<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import type { FormInstance, FormRules } from 'element-plus'
import AppIcon from '@/components/ui/AppIcon.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import SectionHead from '@/components/ui/SectionHead.vue'
import {
  buildPermissionModules,
  collectPermissionIds,
  createRole,
  deleteRole,
  fetchPermissions,
  fetchRolePermissionIds,
  fetchRoles,
  flattenPermissions,
  readableError,
  saveRolePermissions,
  updateRole,
  type PermissionItem,
  type PermissionModule,
  type RoleItem,
} from '@/api/super-admin'
import { USER_TYPE, labelOf } from '@/constants/domain'
import { useUserStore } from '@/stores/user'

/**
 * 角色权限矩阵 —— 这个后台的核心页。
 *
 * 左边是角色，右边是权限项按模块分组的勾选矩阵。选中父权限会连带选中它这一支，
 * 因为后端存的是"角色拥有哪些权限 id"的平铺集合，父项独立存在于集合里，
 * 只勾父项而不勾子项在实际校验里没有意义。
 *
 * 保存是 PUT /super-admin/roles/{id}/permissions，全量覆盖：后端先删掉该角色的
 * 全部绑定，再按提交的 id 重建。所以保存前必须能让管理员看清"这次到底改了什么"，
 * 页面因此在保存按钮旁给出新增 / 移除的条数与名称。
 *
 * 原实现的问题：勾选状态通过一个并不存在的 el-tree 属性传入，勾了也不会回写；
 * check 事件签名写错；保存时把"角色类型"当成角色 id；页面上还留着成片的
 * console.log，把每个权限的勾选状态都打到控制台。
 */

const route = useRoute()
const router = useRouter()
const userStore = useUserStore()

const loading = ref(true)
const error = ref('')
const roles = ref<RoleItem[]>([])
const tree = ref<PermissionItem[]>([])

const activeRoleId = ref<number | null>(null)
const roleLoading = ref(false)
const roleError = ref('')
const saving = ref(false)
const selectedIds = ref<number[]>([])
const originalIds = ref<number[]>([])

const flat = computed(() => flattenPermissions(tree.value))
const modules = computed<PermissionModule[]>(() => buildPermissionModules(tree.value))
const selectedSet = computed(() => new Set(selectedIds.value))
const originalSet = computed(() => new Set(originalIds.value))
const activeRole = computed(() => roles.value.find((role) => role.roleId === activeRoleId.value) ?? null)

/** 树里所有权限（父权限的选中会展开成整支），用来计算集合大小。 */
const totalCount = computed(() => flat.value.length)
const addedItems = computed(() =>
  flat.value.filter((item) => selectedSet.value.has(item.permissionId) && !originalSet.value.has(item.permissionId)),
)
const removedItems = computed(() =>
  flat.value.filter((item) => !selectedSet.value.has(item.permissionId) && originalSet.value.has(item.permissionId)),
)
const dirty = computed(() => addedItems.value.length + removedItems.value.length > 0)

function isChecked(permissionId: number): boolean {
  return selectedSet.value.has(permissionId)
}

function moduleSelectedCount(module: PermissionModule): number {
  return module.items.filter((item) => isChecked(item.permissionId)).length
}

function moduleFullySelected(module: PermissionModule): boolean {
  return moduleSelectedCount(module) === module.items.length
}

/** 勾选一个节点 = 勾选它和它的全部后代；取消同理。 */
function toggleNode(node: PermissionItem) {
  const branch = collectPermissionIds(node)
  if (isChecked(node.permissionId)) {
    selectedIds.value = selectedIds.value.filter((id) => !branch.includes(id))
  } else {
    selectedIds.value = Array.from(new Set([...selectedIds.value, ...branch]))
  }
}

function selectModule(module: PermissionModule) {
  const branch = module.items.flatMap((item) => collectPermissionIds(item))
  selectedIds.value = Array.from(new Set([...selectedIds.value, ...branch]))
}

function clearModule(module: PermissionModule) {
  const branch = new Set(module.items.flatMap((item) => collectPermissionIds(item)))
  selectedIds.value = selectedIds.value.filter((id) => !branch.has(id))
}

function invertModule(module: PermissionModule) {
  const branch = module.items.flatMap((item) => collectPermissionIds(item))
  for (const id of branch) {
    if (selectedSet.value.has(id)) {
      selectedIds.value = selectedIds.value.filter((item) => item !== id)
    } else {
      selectedIds.value = [...selectedIds.value, id]
    }
  }
}

function namesOf(items: PermissionItem[], limit = 8): string {
  const names = items.map((item) => item.permissionName)
  if (names.length <= limit) return names.join('、')
  return `${names.slice(0, limit).join('、')} 等 ${names.length} 项`
}

/* --- 加载 ---------------------------------------------------------------- */

async function loadAll() {
  loading.value = true
  error.value = ''
  try {
    const [roleList, permissions] = await Promise.all([fetchRoles(), fetchPermissions()])
    roles.value = roleList
    tree.value = permissions.tree

    // 默认落在当前登录账号所属的角色上：超管打开这一页，先看到的是自己的权限。
    const wanted = Number(route.query.role)
    const ownType = Number(userStore.userInfo?.userType ?? 0)
    const initial =
      roleList.find((role) => role.roleId === wanted) ??
      roleList.find((role) => role.userType === ownType) ??
      roleList[0]
    if (initial) {
      await selectRole(initial.roleId)
    } else {
      activeRoleId.value = null
    }
  } catch (e) {
    roles.value = []
    tree.value = []
    error.value = readableError(e, '角色与权限加载失败')
  } finally {
    loading.value = false
  }
}

async function selectRole(roleId: number) {
  activeRoleId.value = roleId
  roleLoading.value = true
  roleError.value = ''
  try {
    const ids = await fetchRolePermissionIds(roleId)
    originalIds.value = [...ids]
    selectedIds.value = [...ids]
  } catch (e) {
    originalIds.value = []
    selectedIds.value = []
    roleError.value = readableError(e, '该角色的权限读取失败')
  } finally {
    roleLoading.value = false
  }
}

/** 有未保存的改动时，先问一句再切角色，避免改动被静默丢掉。 */
async function changeRole(roleId: number) {
  if (roleId === activeRoleId.value) return
  if (dirty.value) {
    try {
      await ElMessageBox.confirm(
        '当前角色有未保存的权限改动，切换角色会放弃这些改动。',
        '放弃未保存的改动',
        { confirmButtonText: '放弃并切换', cancelButtonText: '留在本角色', type: 'warning' },
      )
    } catch {
      return
    }
  }
  void router.replace({ query: { ...route.query, role: roleId } })
  await selectRole(roleId)
}

function discardChanges() {
  selectedIds.value = [...originalIds.value]
}

function retryRole() {
  if (activeRoleId.value === null) return
  void selectRole(activeRoleId.value)
}

async function save() {
  if (activeRoleId.value === null || !dirty.value) return
  const roleId = activeRoleId.value
  const added = addedItems.value.length
  const removed = removedItems.value.length
  saving.value = true
  try {
    await saveRolePermissions(roleId, [...new Set(selectedIds.value)].sort((a, b) => a - b))
    originalIds.value = [...selectedIds.value]
    ElMessage.success(`权限已保存：新增 ${added} 项，移除 ${removed} 项`)
  } catch (e) {
    ElMessage.error(readableError(e, '权限保存失败'))
  } finally {
    saving.value = false
  }
}

/* --- 角色维护 ------------------------------------------------------------- */

const roleDialogOpen = ref(false)
const roleSubmitting = ref(false)
const roleFormRef = ref<FormInstance>()
const roleEditingId = ref<number | null>(null)
const roleForm = reactive({
  roleName: '',
  roleCode: '',
  userType: 3,
  description: '',
})

const roleRules: FormRules = {
  roleName: [
    { required: true, message: '请输入角色名称', trigger: 'blur' },
    { min: 2, max: 50, message: '角色名称长度 2 到 50 位', trigger: 'blur' },
  ],
  roleCode: [
    { required: true, message: '请输入角色编码', trigger: 'blur' },
    {
      pattern: /^[A-Z][A-Z0-9_]*$/,
      message: '角色编码用大写字母、数字与下划线，并以字母开头',
      trigger: 'blur',
    },
  ],
}

const userTypeOptions = computed(() =>
  Object.entries(USER_TYPE).map(([code, value]) => ({
    value: Number(code),
    label: value.label,
  })),
)

function openRoleCreate() {
  roleEditingId.value = null
  Object.assign(roleForm, { roleName: '', roleCode: '', userType: 3, description: '' })
  roleDialogOpen.value = true
  void roleFormRef.value?.clearValidate()
}

function openRoleEdit(role: RoleItem) {
  roleEditingId.value = role.roleId
  Object.assign(roleForm, {
    roleName: role.roleName,
    roleCode: role.roleCode,
    userType: role.userType,
    description: role.description ?? '',
  })
  roleDialogOpen.value = true
  void roleFormRef.value?.clearValidate()
}

async function submitRole() {
  if (!roleFormRef.value) return
  try {
    await roleFormRef.value.validate()
  } catch {
    return
  }

  roleSubmitting.value = true
  try {
    const payload = {
      roleName: roleForm.roleName.trim(),
      roleCode: roleForm.roleCode.trim(),
      userType: roleForm.userType,
      description: roleForm.description.trim(),
    }
    if (roleEditingId.value === null) {
      await createRole(payload)
      ElMessage.success('角色已新建，接着为它勾选权限')
    } else {
      await updateRole(roleEditingId.value, payload)
      ElMessage.success('角色已更新')
    }
    roleDialogOpen.value = false
    await loadAll()
  } catch (e) {
    ElMessage.error(readableError(e, '角色保存失败'))
  } finally {
    roleSubmitting.value = false
  }
}

async function removeRole(role: RoleItem) {
  try {
    await ElMessageBox.confirm(
      `删除角色「${role.roleName}」后，它与全部权限的绑定关系同时移除（数据库级联删除）。账号本身不受影响，请确认没有账号还在依赖这个角色。`,
      '删除角色',
      { confirmButtonText: '删除', cancelButtonText: '取消', type: 'warning' },
    )
  } catch {
    return
  }

  try {
    await deleteRole(role.roleId)
    ElMessage.success('角色已删除')
    if (activeRoleId.value === role.roleId) {
      activeRoleId.value = null
      selectedIds.value = []
      originalIds.value = []
    }
    await loadAll()
  } catch (e) {
    ElMessage.error(readableError(e, '角色删除失败'))
  }
}

watch(
  () => route.query.role,
  (value) => {
    const next = Number(value)
    if (!value || Number.isNaN(next) || next === activeRoleId.value) return
    if (roles.value.some((role) => role.roleId === next)) void selectRole(next)
  },
)

onMounted(loadAll)
</script>

<template>
  <div class="page">
    <SectionHead
      title="角色权限矩阵"
      :note="`${roles.length} 个角色 · ${totalCount} 条权限 · 勾选即该角色持有的权限清单`"
      size="lg"
    >
      <template #action>
        <div class="head-actions">
          <button class="btn" type="button" :disabled="loading" @click="loadAll">
            <AppIcon name="refresh" size="14" />
            刷新
          </button>
          <button class="btn" type="button" @click="openRoleCreate">
            <AppIcon name="plus" size="14" />
            新建角色
          </button>
        </div>
      </template>
    </SectionHead>

    <div v-if="loading" class="plate" aria-busy="true">
      <div class="skeleton-layout">
        <div class="skeleton-side">
          <span v-for="n in 4" :key="n" class="skeleton skeleton--role" />
        </div>
        <div class="skeleton-main">
          <span class="skeleton skeleton--line" />
          <span class="skeleton skeleton--line" />
          <span class="skeleton skeleton--line" />
        </div>
      </div>
    </div>

    <div v-else-if="error" class="plate">
      <EmptyState title="角色与权限加载失败" :note="error">
        <button class="btn" type="button" @click="loadAll">
          <AppIcon name="refresh" size="14" />
          重新加载
        </button>
      </EmptyState>
    </div>

    <EmptyState
      v-else-if="roles.length === 0"
      class="plate"
      title="还没有角色"
      note="角色是权限的载体：先建一个角色，再为它勾选权限。"
    >
      <button class="btn btn--solid" type="button" @click="openRoleCreate">新建角色</button>
    </EmptyState>

    <div v-else class="layout">
      <aside class="plate roles" aria-label="角色列表">
        <header class="plate__head">
          <p class="plate__title">角色</p>
          <span class="plate__note">{{ roles.length }} 个</span>
        </header>
        <ul class="roles__list">
          <li
            v-for="role in roles"
            :key="role.roleId"
            class="role"
            :class="{ 'is-active': role.roleId === activeRoleId }"
          >
            <button class="role__pick" type="button" @click="changeRole(role.roleId)">
              <span class="role__name">{{ role.roleName }}</span>
              <span class="role__code mono">{{ role.roleCode }}</span>
              <span class="role__type">{{ labelOf(USER_TYPE, role.userType).label }}</span>
            </button>
            <div class="role__actions">
              <button
                class="icon-btn"
                type="button"
                :aria-label="`编辑角色 ${role.roleName}`"
                @click="openRoleEdit(role)"
              >
                <AppIcon name="edit" size="14" />
              </button>
              <button
                class="icon-btn icon-btn--danger"
                type="button"
                :aria-label="`删除角色 ${role.roleName}`"
                @click="removeRole(role)"
              >
                <AppIcon name="trash" size="14" />
              </button>
            </div>
          </li>
        </ul>
      </aside>

      <section class="plate matrix">
        <header class="plate__head matrix__head">
          <div>
            <p class="plate__title">
              {{ activeRole ? `${activeRole.roleName} 的权限` : '选择左侧角色' }}
              <span v-if="activeRole" class="mono plate__code">{{ activeRole.roleCode }}</span>
            </p>
            <p class="plate__note">
              已选 {{ selectedIds.length }} 项 / 共 {{ totalCount }} 项
              <template v-if="dirty">
                · 本次改动：新增 {{ addedItems.length }} 项，移除 {{ removedItems.length }} 项
              </template>
              <template v-else> · 与已保存的配置一致</template>
            </p>
          </div>
          <div class="matrix__actions">
            <button class="btn" type="button" :disabled="!dirty || saving" @click="discardChanges">
              放弃改动
            </button>
            <button class="btn btn--solid" type="button" :disabled="!dirty || saving" @click="save">
              {{ saving ? '保存中…' : '保存权限' }}
            </button>
          </div>
        </header>

        <div v-if="dirty" class="diff">
          <p v-if="addedItems.length" class="diff__row">
            <span class="mark mark--add">将新增</span>
            <span class="diff__names">{{ namesOf(addedItems) }}</span>
          </p>
          <p v-if="removedItems.length" class="diff__row">
            <span class="mark mark--remove">将移除</span>
            <span class="diff__names">{{ namesOf(removedItems) }}</span>
          </p>
        </div>

        <div v-if="roleLoading" class="plate__body">
          <div v-for="n in 5" :key="n" class="ghost-row">
            <span class="ghost skeleton" />
            <span class="ghost ghost--sm skeleton" />
          </div>
        </div>

        <div v-else-if="roleError" class="plate__body">
          <EmptyState title="这个角色的权限读取失败" :note="roleError">
            <button class="btn" type="button" @click="retryRole">
              <AppIcon name="refresh" size="14" />
              重新加载
            </button>
          </EmptyState>
        </div>

        <EmptyState
          v-else-if="modules.length === 0"
          title="还没有权限项"
          note="先去权限清单建立权限项，这里才有可以勾选的内容。"
        >
          <RouterLink class="btn btn--solid" to="/super-admin-dashboard/permission-list">
            去权限清单
          </RouterLink>
        </EmptyState>

        <div v-else class="matrix__body">
          <div v-for="module in modules" :key="module.key" class="module">
            <div class="module__head">
              <div class="module__title">
                <span class="module__name">{{ module.title }}</span>
                <span class="mono module__code">{{ module.code }}</span>
              </div>
              <div class="module__meta">
                <span class="module__count">
                  {{ moduleSelectedCount(module) }} / {{ module.items.length }}
                </span>
                <button
                  class="link"
                  type="button"
                  :disabled="moduleFullySelected(module)"
                  @click="selectModule(module)"
                >
                  全选
                </button>
                <button
                  class="link"
                  type="button"
                  :disabled="moduleSelectedCount(module) === 0"
                  @click="clearModule(module)"
                >
                  清空
                </button>
                <button class="link" type="button" @click="invertModule(module)">反选</button>
              </div>
            </div>

            <ul class="items">
              <li v-for="item in module.items" :key="item.permissionId" class="item">
                <label class="check">
                  <input
                    type="checkbox"
                    :checked="isChecked(item.permissionId)"
                    @change="toggleNode(item)"
                  />
                  <span class="check__name">{{ item.permissionName }}</span>
                  <span
                    v-if="selectedSet.has(item.permissionId) && !originalSet.has(item.permissionId)"
                    class="mark mark--add"
                  >
                    新增
                  </span>
                  <span
                    v-else-if="!selectedSet.has(item.permissionId) && originalSet.has(item.permissionId)"
                    class="mark mark--remove"
                  >
                    移除
                  </span>
                  <span class="check__code mono">{{ item.permissionCode }}</span>
                  <span class="check__url mono">{{ item.url }}</span>
                </label>
              </li>
            </ul>
          </div>
        </div>
      </section>
    </div>

    <el-dialog
      v-model="roleDialogOpen"
      :title="roleEditingId === null ? '新建角色' : '编辑角色'"
      width="480px"
    >
      <el-form ref="roleFormRef" :model="roleForm" :rules="roleRules" label-position="top">
        <el-form-item label="角色名称" prop="roleName">
          <el-input v-model="roleForm.roleName" placeholder="如：运营管理员" maxlength="50" />
        </el-form-item>
        <el-form-item label="角色编码" prop="roleCode">
          <el-input v-model="roleForm.roleCode" placeholder="如：ADMIN_OP" maxlength="50" />
        </el-form-item>
        <el-form-item label="对应账号类型">
          <el-radio-group v-model="roleForm.userType">
            <el-radio v-for="option in userTypeOptions" :key="option.value" :value="option.value">
              {{ option.label }}
            </el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="角色说明">
          <el-input
            v-model="roleForm.description"
            type="textarea"
            :rows="3"
            placeholder="这个角色负责什么，方便后来的人判断该给哪些权限"
            maxlength="200"
          />
        </el-form-item>
      </el-form>

      <template #footer>
        <div class="dialog-foot">
          <button class="btn" type="button" @click="roleDialogOpen = false">取消</button>
          <button class="btn btn--solid" type="button" :disabled="roleSubmitting" @click="submitRole">
            {{ roleSubmitting ? '保存中…' : '保存' }}
          </button>
        </div>
      </template>
    </el-dialog>
  </div>
</template>

<style scoped>
.page {
  max-width: var(--shell-max);
  margin-inline: auto;
  padding-bottom: var(--space-8);
}

.head-actions {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-2);
}

.layout {
  display: grid;
  grid-template-columns: 268px minmax(0, 1fr);
  gap: var(--gap-surface);
  align-items: start;
}

/* --- 角色列表 ------------------------------------------------------------ */

.roles {
  position: sticky;
  top: var(--space-4);
}

.roles .plate__head {
  align-items: baseline;
}

.roles__list {
  display: flex;
  flex-direction: column;
  margin: 0;
  padding: var(--space-2);
  list-style: none;
  gap: 2px;
}

.role {
  display: flex;
  align-items: center;
  gap: var(--space-1);
  border-radius: var(--radius-sm);
}

.role.is-active {
  background: var(--paper-2);
}

.role__pick {
  display: flex;
  flex-direction: column;
  gap: 1px;
  flex: 1;
  min-width: 0;
  padding: var(--space-2) var(--space-3);
  border: none;
  border-radius: var(--radius-sm);
  background: transparent;
  text-align: left;
  cursor: pointer;
}

.role__pick:hover {
  background: var(--paper-1);
}

.role.is-active .role__pick:hover {
  background: transparent;
}

.role__name {
  color: var(--ink-0);
  font-size: var(--text-sm);
  font-weight: 600;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.role__code {
  color: var(--ink-3);
  font-size: var(--text-2xs);
}

.role__type {
  color: var(--ink-4);
  font-size: var(--text-2xs);
}

.role__actions {
  display: flex;
  flex-shrink: 0;
  padding-right: var(--space-1);
}

.icon-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 26px;
  height: 26px;
  border: none;
  border-radius: var(--radius-sm);
  background: transparent;
  color: var(--ink-3);
  cursor: pointer;
}

.icon-btn:hover {
  background: var(--paper-3);
  color: var(--ink-0);
}

.icon-btn--danger:hover {
  color: var(--signal-vermilion-deep);
}

/* --- 矩阵 ---------------------------------------------------------------- */

.matrix {
  min-width: 0;
}

.matrix__head {
  align-items: flex-start;
  flex-wrap: wrap;
  gap: var(--space-3);
}

.plate__code {
  margin-left: var(--space-2);
  color: var(--ink-3);
  font-weight: 500;
}

.matrix__actions {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-2);
}

.diff {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
  padding: var(--space-3) var(--pad-surface);
  background: var(--paper-1);
  border-bottom: var(--hairline);
}

.diff__row {
  display: flex;
  align-items: flex-start;
  gap: var(--space-2);
  max-width: none;
}

.diff__names {
  color: var(--ink-2);
  font-size: var(--text-xs);
  line-height: 22px;
}

.matrix__body {
  display: flex;
  flex-direction: column;
}

.module {
  border-bottom: var(--hairline);
}

.module:last-child {
  border-bottom: none;
}

.module__head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: var(--space-2) var(--space-3);
  padding: var(--space-2) var(--pad-surface);
  background: var(--paper-1);
}

.module__title {
  display: flex;
  align-items: baseline;
  gap: var(--space-2);
  min-width: 0;
}

.module__name {
  color: var(--ink-0);
  font-size: var(--text-sm);
  font-weight: 600;
}

.module__code {
  color: var(--ink-3);
  font-size: var(--text-2xs);
}

.module__meta {
  display: flex;
  align-items: center;
  gap: var(--space-3);
}

.module__count {
  color: var(--ink-3);
  font-size: var(--text-xs);
  font-variant-numeric: tabular-nums;
}

.items {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(272px, 1fr));
  gap: 1px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.item {
  min-width: 0;
  border-bottom: var(--hairline);
}

.check {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  padding: var(--space-2) var(--pad-surface);
  cursor: pointer;
}

.check:hover {
  background: var(--paper-1);
}

.check input[type='checkbox'] {
  flex-shrink: 0;
  width: 14px;
  height: 14px;
  accent-color: var(--ink-0);
  cursor: pointer;
}

.check__name {
  flex-shrink: 0;
  color: var(--ink-1);
  font-size: var(--text-sm);
}

.check__code {
  flex-shrink: 0;
  color: var(--ink-3);
  font-size: var(--text-2xs);
}

.check__url {
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  color: var(--ink-4);
  font-size: var(--text-2xs);
}

.mark {
  flex-shrink: 0;
  height: 18px;
  padding-inline: 6px;
  border-radius: var(--radius-xs);
  font-size: var(--text-2xs);
  font-weight: 600;
  line-height: 18px;
}

.mark--add {
  background: var(--signal-teal-wash);
  color: var(--signal-teal-deep);
}

.mark--remove {
  background: var(--signal-vermilion-wash);
  color: var(--signal-vermilion-deep);
}

.link {
  padding: 0;
  border: none;
  background: transparent;
  color: var(--ink-2);
  font-size: var(--text-xs);
  font-weight: 500;
  cursor: pointer;
}

.link:hover:not(:disabled) {
  color: var(--signal-amber-deep);
  text-decoration: underline;
}

.link:disabled {
  color: var(--ink-4);
  cursor: not-allowed;
}

/* --- 骨架与控件 ---------------------------------------------------------- */

.skeleton-layout {
  display: grid;
  grid-template-columns: 268px minmax(0, 1fr);
  gap: var(--gap-surface);
  padding: var(--pad-surface);
}

.skeleton-side {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
}

.skeleton-main {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
}

.skeleton {
  display: block;
}

.skeleton--role {
  height: 34px;
}

.skeleton--line {
  height: 42px;
}

.ghost-row {
  display: flex;
  align-items: center;
  gap: var(--space-4);
}

.ghost-row + .ghost-row {
  margin-top: var(--space-3);
}

.ghost {
  height: 16px;
  width: 32%;
}

.ghost--sm {
  width: 14%;
}

.dialog-foot {
  display: flex;
  justify-content: flex-end;
  gap: var(--space-2);
}

.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  height: var(--control-h);
  padding-inline: 14px;
  border: var(--edge);
  border-radius: var(--radius-sm);
  background: var(--paper-0);
  color: var(--ink-1);
  font-size: var(--text-sm);
  font-weight: 500;
  text-decoration: none;
  cursor: pointer;
  white-space: nowrap;
  transition:
    border-color var(--dur-state) ease,
    background-color var(--dur-state) ease,
    color var(--dur-state) ease;
}

.btn:hover:not(:disabled) {
  border-color: var(--ink-3);
  text-decoration: none;
}

.btn--solid {
  border-color: var(--ink-0);
  background: var(--ink-0);
  color: var(--on-ink);
  font-weight: 600;
}

.btn--solid:hover:not(:disabled) {
  background: #262d33;
  border-color: #262d33;
}

.btn:disabled {
  border-color: var(--line-2);
  background: var(--paper-2);
  color: var(--ink-4);
  cursor: not-allowed;
}

@media (max-width: 1000px) {
  .layout,
  .skeleton-layout {
    grid-template-columns: minmax(0, 1fr);
  }

  .roles {
    position: static;
  }

  .roles__list {
    flex-direction: row;
    flex-wrap: wrap;
  }

  .role {
    border: var(--edge);
  }

  .role.is-active {
    border-color: var(--ink-0);
    background: var(--paper-3);
  }
}

@media (max-width: 640px) {
  .module__head {
    align-items: flex-start;
    flex-direction: column;
  }

  .items {
    grid-template-columns: minmax(0, 1fr);
  }

  .check {
    flex-wrap: wrap;
  }

  .check__url {
    flex-basis: 100%;
  }
}
</style>
