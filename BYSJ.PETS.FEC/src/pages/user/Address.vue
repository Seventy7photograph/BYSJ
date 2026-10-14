<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox, type FormInstance, type FormRules } from 'element-plus'
import { regionData } from 'element-china-area-data'
import AppIcon from '@/components/ui/AppIcon.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import SectionHead from '@/components/ui/SectionHead.vue'
import StatePill from '@/components/ui/StatePill.vue'
import { useUserStore } from '@/stores/user'
import {
  addAddress,
  deleteAddress,
  getAddressList,
  setDefaultAddress,
  updateAddress,
  type AddressItem,
} from '@/api/user/address'
import { maskPhone } from '@/utils/format'

/**
 * 收货地址管理。
 *
 * 几处修正：
 *   - 原来读列表用 `addresses.length > 0` 控制「新增」按钮，导致空列表时连新增
 *     入口都没有，页面彻底没有出口；空态现在自己带新增动作。
 *   - 编辑时把整条地址 Object.assign 进表单，连 userId、addressId 一起回传，
 *     这里只提交后端需要的字段。
 *   - isDefault 在数据库里是 0/1 的整数，界面用布尔值，进出各转一次。
 *   - 删掉了不存在的 getAddressDetail 调用；编辑直接用列表里的数据。
 */
const router = useRouter()
const userStore = useUserStore()

const list = ref<AddressItem[]>([])
const loading = ref(true)
const error = ref('')
const saving = ref(false)
const dialogVisible = ref(false)
const editing = ref(false)
const formRef = ref<FormInstance>()

const form = reactive({
  addressId: null as number | null,
  recipient: '',
  phone: '',
  province: '',
  city: '',
  district: '',
  detail: '',
  isDefault: false,
})

/** 级联选择器的值，用名称数组进入表单，与后端存的省/市/区文本一致。 */
const region = ref<string[]>([])

const regionOptions = regionData

const dialogTitle = computed(() => (editing.value ? '编辑收货地址' : '新增收货地址'))

const fullAddress = (item: AddressItem) =>
  `${item.province ?? ''}${item.city ?? ''}${item.district ?? ''}${item.detail ?? ''}`

const rules: FormRules = {
  recipient: [{ required: true, message: '请填写收货人姓名', trigger: 'blur' }],
  phone: [
    { required: true, message: '请填写手机号码', trigger: 'blur' },
    { pattern: /^1[3-9]\d{9}$/, message: '手机号码格式不正确', trigger: 'blur' },
  ],
  detail: [
    { required: true, message: '请填写详细地址', trigger: 'blur' },
    { min: 4, message: '详细地址太短，请补全门牌号', trigger: 'blur' },
  ],
}

async function load() {
  loading.value = true
  error.value = ''
  try {
    list.value = await getAddressList()
  } catch (e: any) {
    error.value = e?.msg || (e instanceof Error ? e.message : '地址加载失败，请稍后重试')
    list.value = []
  } finally {
    loading.value = false
  }
}

function resetForm() {
  form.addressId = null
  form.recipient = ''
  form.phone = ''
  form.province = ''
  form.city = ''
  form.district = ''
  form.detail = ''
  form.isDefault = list.value.length === 0
  region.value = []
  formRef.value?.clearValidate()
}

function openCreate() {
  editing.value = false
  resetForm()
  dialogVisible.value = true
}

function openEdit(item: AddressItem) {
  editing.value = true
  form.addressId = item.addressId
  form.recipient = item.recipient
  form.phone = item.phone
  form.province = item.province
  form.city = item.city
  form.district = item.district
  form.detail = item.detail
  form.isDefault = Number(item.isDefault) === 1
  region.value = [item.province, item.city, item.district].filter(Boolean)
  formRef.value?.clearValidate()
  dialogVisible.value = true
}

function onRegion(value: string[] | null) {
  if (value && value.length === 3) {
    form.province = value[0]!
    form.city = value[1]!
    form.district = value[2]!
  } else {
    form.province = ''
    form.city = ''
    form.district = ''
  }
}

async function save() {
  if (!formRef.value) return
  if (!form.province || !form.city || !form.district) {
    ElMessage.warning('请选择所在地区')
    return
  }
  try {
    await formRef.value.validate()
  } catch {
    return
  }

  saving.value = true
  const payload = {
    recipient: form.recipient.trim(),
    phone: form.phone.trim(),
    province: form.province,
    city: form.city,
    district: form.district,
    detail: form.detail.trim(),
    isDefault: form.isDefault ? 1 : 0,
  }
  try {
    if (editing.value && form.addressId) {
      await updateAddress({ ...payload, addressId: form.addressId })
    } else {
      await addAddress(payload)
    }
    ElMessage.success(editing.value ? '地址已更新' : '地址已添加')
    dialogVisible.value = false
    await load()
  } catch (e: any) {
    ElMessage.error(e?.msg || (e instanceof Error ? e.message : '保存失败，请稍后重试'))
  } finally {
    saving.value = false
  }
}

async function makeDefault(item: AddressItem) {
  try {
    await setDefaultAddress(item.addressId)
    ElMessage.success('已设为默认地址')
    await load()
  } catch (e: any) {
    ElMessage.error(e?.msg || '设置失败，请稍后重试')
  }
}

async function remove(item: AddressItem) {
  try {
    await ElMessageBox.confirm(`删除「${item.recipient} ${maskPhone(item.phone)}」这条地址？`, '删除地址', {
      confirmButtonText: '删除',
      cancelButtonText: '取消',
      type: 'warning',
    })
  } catch {
    return
  }
  try {
    await deleteAddress(item.addressId)
    ElMessage.success('地址已删除')
    await load()
  } catch (e: any) {
    ElMessage.error(e?.msg || '删除失败，请稍后重试')
  }
}

onMounted(() => {
  if (!userStore.isLoggedIn) {
    router.push('/login')
    return
  }
  void load()
})
</script>

<template>
  <div class="shell addresses">
    <SectionHead
      title="收货地址"
      :note="list.length ? `共 ${list.length} 个地址，下单时可直接选用` : '下单前需要至少一个收货地址'"
      size="lg"
    >
      <template #action>
        <button class="btn" type="button" @click="openCreate">
          <AppIcon name="plus" size="14" />
          新增收货地址
        </button>
      </template>
    </SectionHead>

    <!-- 加载 -->
    <div v-if="loading" class="grid" aria-busy="true">
      <div v-for="n in 4" :key="n" class="ghost">
        <div class="ghost__line skeleton" />
        <div class="ghost__line ghost__line--short skeleton" />
        <div class="ghost__line skeleton" />
      </div>
    </div>

    <!-- 错误 -->
    <div v-else-if="error" class="plate state">
      <AppIcon name="warning" size="22" />
      <p class="state__title">地址没能加载出来</p>
      <p class="state__note">{{ error }}</p>
      <button class="btn" type="button" @click="load">
        <AppIcon name="refresh" size="14" />
        重新加载
      </button>
    </div>

    <!-- 空态 -->
    <EmptyState
      v-else-if="!list.length"
      title="还没有收货地址"
      note="添加一个常用的地址，下单时就不用每次重新填写。"
    >
      <button class="btn" type="button" @click="openCreate">
        <AppIcon name="plus" size="14" />
        新增收货地址
      </button>
    </EmptyState>

    <ul v-else class="grid">
      <li v-for="item in list" :key="item.addressId" class="addr">
        <div class="addr__head">
          <span class="addr__name">{{ item.recipient }}</span>
          <span class="addr__phone">{{ maskPhone(item.phone) }}</span>
          <StatePill v-if="Number(item.isDefault) === 1" label="默认地址" tone="teal" />
        </div>

        <p class="addr__detail">{{ fullAddress(item) }}</p>

        <div class="addr__actions">
          <button
            v-if="Number(item.isDefault) !== 1"
            class="link"
            type="button"
            @click="makeDefault(item)"
          >
            设为默认
          </button>
          <button class="link" type="button" @click="openEdit(item)">编辑</button>
          <button class="link link--danger" type="button" @click="remove(item)">删除</button>
        </div>
      </li>
    </ul>

    <el-dialog
      v-model="dialogVisible"
      :title="dialogTitle"
      width="min(520px, 92vw)"
      @closed="resetForm"
    >
      <el-form ref="formRef" :model="form" :rules="rules" label-position="top" @submit.prevent>
        <el-form-item label="收货人" prop="recipient">
          <el-input v-model="form.recipient" maxlength="20" placeholder="收件人姓名" />
        </el-form-item>

        <el-form-item label="手机号码" prop="phone">
          <el-input v-model="form.phone" maxlength="11" placeholder="11 位手机号" />
        </el-form-item>

        <el-form-item label="所在地区">
          <el-cascader
            v-model="region"
            class="region"
            :options="regionOptions"
            :props="{ value: 'label', label: 'label', children: 'children' }"
            placeholder="省 / 市 / 区"
            @change="onRegion"
          />
        </el-form-item>

        <el-form-item label="详细地址" prop="detail">
          <el-input
            v-model="form.detail"
            type="textarea"
            :rows="3"
            maxlength="120"
            show-word-limit
            placeholder="街道、门牌号、楼栋与房间号"
          />
        </el-form-item>

        <el-form-item>
          <el-checkbox v-model="form.isDefault">设为默认地址</el-checkbox>
        </el-form-item>
      </el-form>

      <template #footer>
        <div class="dialog-foot">
          <button class="btn" type="button" @click="dialogVisible = false">取消</button>
          <button class="btn btn--primary" type="button" :disabled="saving" @click="save">
            {{ saving ? '保存中…' : '保存' }}
          </button>
        </div>
      </template>
    </el-dialog>
  </div>
</template>

<style scoped>
.addresses {
  max-width: 1000px;
  padding-block: var(--space-6) var(--space-16);
}

.grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
  gap: var(--space-4);
  margin: 0;
  padding: 0;
  list-style: none;
}

/* --- address card --------------------------------------------------------- */

.addr {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
  background: var(--paper-0);
  border: var(--edge);
  border-radius: var(--radius-md);
}

.addr__head {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: var(--space-2);
  padding: var(--space-3) var(--space-4) 0;
}

.addr__name {
  font-size: var(--text-base);
  font-weight: 600;
  color: var(--ink-0);
}

.addr__phone {
  font-size: var(--text-sm);
  color: var(--ink-2);
  font-variant-numeric: tabular-nums;
}

.addr__detail {
  padding-inline: var(--space-4);
  font-size: var(--text-sm);
  line-height: 1.6;
  color: var(--ink-2);
}

.addr__actions {
  display: flex;
  gap: var(--space-4);
  padding: 10px var(--space-4);
  border-top: var(--hairline);
  background: var(--paper-1);
  border-radius: 0 0 var(--radius-md) var(--radius-md);
}

/* --- primitives ----------------------------------------------------------- */

.btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 34px;
  padding-inline: 14px;
  border: 1px solid var(--line-2);
  border-radius: var(--radius-sm);
  background: var(--paper-0);
  font-size: var(--text-sm);
  font-weight: 500;
  color: var(--ink-1);
  cursor: pointer;
  transition:
    background-color var(--dur-state) ease,
    border-color var(--dur-state) ease,
    color var(--dur-state) ease;
}

.btn:hover:not(:disabled) {
  border-color: var(--ink-3);
  background: var(--paper-1);
  text-decoration: none;
}

.btn:disabled {
  color: var(--ink-4);
  border-color: var(--line-1);
  cursor: not-allowed;
}

.btn--primary {
  background: var(--ink-0);
  border-color: var(--ink-0);
  color: var(--on-ink);
}

.btn--primary:hover:not(:disabled) {
  background: var(--ink-1);
  border-color: var(--ink-1);
  color: var(--on-ink);
}

.btn--primary:disabled {
  background: var(--ink-4);
  border-color: var(--ink-4);
  color: var(--paper-0);
}

.link {
  padding: 0;
  border: none;
  background: transparent;
  font-size: var(--text-xs);
  color: var(--ink-2);
  cursor: pointer;
}

.link:hover {
  color: var(--ink-0);
  text-decoration: underline;
}

.link--danger:hover {
  color: var(--signal-vermilion-deep);
}

/* --- states & skeleton ---------------------------------------------------- */

.state {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: var(--space-2);
  padding: var(--space-12) var(--space-6);
  text-align: center;
  color: var(--ink-3);
}

.state__title {
  font-size: var(--text-md);
  font-weight: 600;
  color: var(--ink-1);
}

.state__note {
  font-size: var(--text-sm);
  max-width: 42ch;
}

.ghost {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
  padding: var(--space-5) var(--space-4);
  background: var(--paper-0);
  border: var(--edge);
  border-radius: var(--radius-md);
}

.ghost__line {
  height: 12px;
  border-radius: var(--radius-xs);
}

.ghost__line--short {
  width: 46%;
}

/* --- dialog --------------------------------------------------------------- */

.region {
  width: 100%;
}

.dialog-foot {
  display: flex;
  justify-content: flex-end;
  gap: var(--space-2);
}

@media (max-width: 900px) {
  .addresses {
    padding-block: var(--space-4) var(--space-12);
  }
}

@media (max-width: 520px) {
  .grid {
    grid-template-columns: minmax(0, 1fr);
  }
}
</style>
