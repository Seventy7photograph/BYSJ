package bysj.pets.bec.controller;

import bysj.pets.bec.entity.User;
import bysj.pets.bec.entity.Permission;
import bysj.pets.bec.entity.Role;
import bysj.pets.bec.entity.RolePermission;
import bysj.pets.bec.mapper.UserMapper;
import bysj.pets.bec.mapper.PermissionMapper;
import bysj.pets.bec.mapper.RoleMapper;
import bysj.pets.bec.mapper.RolePermissionMapper;
import bysj.pets.bec.config.Result;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import jakarta.annotation.Resource;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/super-admin")
public class SuperAdminController {

    @Resource
    private UserMapper userMapper;

    @Resource
    private PermissionMapper permissionMapper;
    
    @Resource
    private RoleMapper roleMapper;
    
    @Resource
    private RolePermissionMapper rolePermissionMapper;
    
    @Resource
    private PasswordEncoder passwordEncoder;

    // 管理员管理
    // 获取管理员列表
    @GetMapping("/admins")
    public Result getAdmins(@RequestParam(defaultValue = "1") Integer page,
                           @RequestParam(defaultValue = "10") Integer pageSize,
                           @RequestParam(required = false) String username,
                           @RequestParam(required = false) String phone,
                           @RequestParam(required = false) Integer status) {
        QueryWrapper<User> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("user_type", 3); // 管理员
        
        if (username != null && !username.isEmpty()) {
            queryWrapper.like("username", username);
        }
        
        if (phone != null && !phone.isEmpty()) {
            queryWrapper.like("phone", phone);
        }
        
        if (status != null) {
            queryWrapper.eq("status", status);
        }
        
        Page<User> adminPage = userMapper.selectPage(new Page<>(page, pageSize), queryWrapper);
        return Result.success(adminPage);
    }

    // 新增管理员
    @PostMapping("/admins")
    public Result addAdmin(@RequestBody User user) {
        user.setUserType((byte) 3); // 设置为管理员
        user.setCreateTime(LocalDateTime.now());
        user.setUpdateTime(LocalDateTime.now());
        // 对密码进行BCrypt加密
        if (user.getPassword() != null && !user.getPassword().isEmpty()) {
            user.setPassword(passwordEncoder.encode(user.getPassword()));
        }
        userMapper.insert(user);
        return Result.success("管理员添加成功");
    }

    // 更新管理员信息
    @PutMapping("/admins/{id}")
    public Result updateAdmin(@PathVariable Long id, @RequestBody User user) {
        UpdateWrapper<User> updateWrapper = new UpdateWrapper<>();
        updateWrapper.eq("user_id", id)
                .set("username", user.getUsername())
                .set("nickname", user.getNickname())
                .set("phone", user.getPhone())
                .set("email", user.getEmail())
                .set("status", user.getStatus())
                .set("update_time", LocalDateTime.now());
        if (user.getPassword() != null && !user.getPassword().isEmpty()) {
            // 对密码进行BCrypt加密
            updateWrapper.set("password", passwordEncoder.encode(user.getPassword()));
        }
        userMapper.update(null, updateWrapper);
        return Result.success("管理员更新成功");
    }

    // 删除管理员
    @DeleteMapping("/admins/{id}")
    public Result deleteAdmin(@PathVariable Long id) {
        userMapper.deleteById(id);
        return Result.success("管理员删除成功");
    }

    // 禁用/启用管理员
    @PutMapping("/admins/{id}/status")
    public Result updateAdminStatus(@PathVariable Long id, @RequestParam Integer status) {
        UpdateWrapper<User> updateWrapper = new UpdateWrapper<>();
        updateWrapper.eq("user_id", id)
                .set("status", (byte) status.intValue())
                .set("update_time", LocalDateTime.now());
        userMapper.update(null, updateWrapper);
        return Result.success("操作成功");
    }

    // 权限管理
    // 获取权限列表
    @GetMapping("/permissions")
    public Result getPermissions() {
        QueryWrapper<Permission> queryWrapper = new QueryWrapper<>();
        queryWrapper.isNull("parent_id"); // 顶级权限
        List<Permission> rootPermissions = permissionMapper.selectList(queryWrapper);
        System.out.println("顶级权限数量: " + rootPermissions.size());
        for (Permission permission : rootPermissions) {
            System.out.println("顶级权限: " + permission.getPermissionName() + " (" + permission.getPermissionId() + ")");
        }
        // 递归构建权限树形结构
        buildPermissionTree(rootPermissions);
        System.out.println("构建后权限树: " + rootPermissions);
        return Result.success(rootPermissions);
    }

    // 递归构建权限树形结构
    private void buildPermissionTree(List<Permission> permissions) {
        for (Permission permission : permissions) {
            QueryWrapper<Permission> childQuery = new QueryWrapper<>();
            childQuery.eq("parent_id", permission.getPermissionId());
            List<Permission> children = permissionMapper.selectList(childQuery);
            permission.setChildren(children);
            buildPermissionTree(children);
        }
    }

    // 新增权限
    @PostMapping("/permissions")
    public Result addPermission(@RequestBody Permission permission) {
        permissionMapper.insert(permission);
        return Result.success("权限添加成功");
    }

    // 更新权限
    @PutMapping("/permissions/{id}")
    public Result updatePermission(@PathVariable Integer id, @RequestBody Permission permission) {
        permission.setPermissionId(id);
        permissionMapper.updateById(permission);
        return Result.success("权限更新成功");
    }

    // 删除权限
    @DeleteMapping("/permissions/{id}")
    public Result deletePermission(@PathVariable Integer id) {
        permissionMapper.deleteById(id);
        return Result.success("权限删除成功");
    }

    // 角色管理
    // 获取角色列表
    @GetMapping("/roles")
    public Result getRoles() {
        List<Role> roles = roleMapper.selectList(null);
        return Result.success(roles);
    }

    // 获取角色详情
    @GetMapping("/roles/{id}")
    public Result getRoleDetail(@PathVariable Integer id) {
        Role role = roleMapper.selectById(id);
        if (role == null) {
            return Result.error("角色不存在");
        }
        return Result.success(role);
    }

    // 新增角色
    @PostMapping("/roles")
    public Result addRole(@RequestBody Role role) {
        roleMapper.insert(role);
        return Result.success("角色添加成功");
    }

    // 更新角色
    @PutMapping("/roles/{id}")
    public Result updateRole(@PathVariable Integer id, @RequestBody Role role) {
        role.setRoleId(id);
        roleMapper.updateById(role);
        return Result.success("角色更新成功");
    }

    // 删除角色
    @DeleteMapping("/roles/{id}")
    public Result deleteRole(@PathVariable Integer id) {
        roleMapper.deleteById(id);
        return Result.success("角色删除成功");
    }

    // 获取角色权限
    @GetMapping("/roles/{id}/permissions")
    public Result getRolePermissions(@PathVariable Integer id) {
        QueryWrapper<RolePermission> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("role_id", id);
        List<RolePermission> rolePermissions = rolePermissionMapper.selectList(queryWrapper);
        
        // 获取权限详情
        List<Permission> permissions = new java.util.ArrayList<>();
        for (RolePermission rp : rolePermissions) {
            Permission permission = permissionMapper.selectById(rp.getPermissionId());
            if (permission != null) {
                permissions.add(permission);
            }
        }
        
        return Result.success(permissions);
    }

    // 分配权限给角色
    @PutMapping("/roles/{id}/permissions")
    public Result assignPermissions(@PathVariable Integer id, @RequestBody java.util.Map<String, List<Integer>> request) {
        List<Integer> permissionIds = request.get("permissionIds");
        
        // 先删除该角色的所有权限
        QueryWrapper<RolePermission> deleteWrapper = new QueryWrapper<>();
        deleteWrapper.eq("role_id", id);
        rolePermissionMapper.delete(deleteWrapper);
        
        // 再添加新的权限
        for (Integer permissionId : permissionIds) {
            RolePermission rolePermission = new RolePermission();
            rolePermission.setRoleId(id);
            rolePermission.setPermissionId(permissionId);
            rolePermission.setCreateTime(LocalDateTime.now());
            rolePermissionMapper.insert(rolePermission);
        }
        
        return Result.success("权限分配成功");
    }
}
