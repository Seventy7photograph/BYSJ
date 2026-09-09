package bysj.pets.bec.service.impl;

import bysj.pets.bec.entity.User;
import bysj.pets.bec.mapper.UserMapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import jakarta.annotation.Resource;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;


@Service
public class UserDetailsServiceImpl implements UserDetailsService {

    @Resource
    private UserMapper userMapper;

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        User user = null;
        
        // 尝试先通过用户名查询
        user = userMapper.selectOne(Wrappers.<User>lambdaQuery()
                .eq(User::getUsername, username));
        
        // 如果通过用户名查询不到，尝试通过userId查询
        if (user == null) {
            try {
                Long userId = Long.parseLong(username);
                user = userMapper.selectById(userId);
            } catch (NumberFormatException e) {
                // 如果不是有效的数字，说明既不是用户名也不是userId，直接抛出异常
                throw new UsernameNotFoundException("用户不存在");
            }
        }

        if (user == null) {
            throw new UsernameNotFoundException("用户不存在");
        }

        // 检查账号状态（1-正常，0-禁用，2-待审核）
        if (user.getStatus() == 0) {
            throw new UsernameNotFoundException("账号已被禁用，请联系管理员");
        }

        // 转换为Spring Security用户对象（需导入org.springframework.security.core.userdetails.User）
        return org.springframework.security.core.userdetails.User
                .withUsername(user.getUsername())
                .password(user.getPassword())
                .roles(getRolesByUserType(user.getUserType())) // 根据用户类型分配角色
                .build();
    }

    // 将用户类型转换为Security角色
    private String[] getRolesByUserType(Byte userType) {
        switch (userType) {
            case 1: return new String[]{"USER"};
            case 2: return new String[]{"MERCHANT"};
            case 3: return new String[]{"ADMIN"};
            case 4: return new String[]{"SUPER_ADMIN"};
            default: return new String[]{"USER"};
        }
    }
}