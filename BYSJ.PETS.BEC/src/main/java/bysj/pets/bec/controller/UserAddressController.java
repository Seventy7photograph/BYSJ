package bysj.pets.bec.controller;

import bysj.pets.bec.config.Result;
import bysj.pets.bec.entity.UserAddress;
import bysj.pets.bec.mapper.UserAddressMapper;
import bysj.pets.bec.mapper.UserMapper;
import bysj.pets.bec.utils.JwtUtils;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 用户地址控制器
 */
@RestController
@RequestMapping("/user/addresses")
public class UserAddressController {

    @Autowired
    private UserAddressMapper userAddressMapper;

    @Autowired
    private UserMapper userMapper;

    @Autowired
    private JwtUtils jwtUtils;

    /**
     * 获取用户地址列表
     */
    @GetMapping
    public Result<List<UserAddress>> getUserAddresses(
            @RequestHeader(value = "Authorization", required = false) String tokenHeader) {
        // 验证JWT令牌
        if (tokenHeader == null || !tokenHeader.startsWith("Bearer ")) {
            return Result.error("用户未登录");
        }
        String token = tokenHeader.substring(7);
        if (token == null || token.isEmpty()) {
            return Result.error("用户未登录或令牌已过期");
        }

        // 使用JwtUtils提取用户名
        String username = jwtUtils.getUsernameFromToken(token);
        if (username == null) {
            return Result.error("用户未登录或令牌已过期");
        }

        // 根据用户名获取用户ID
        Long userId = userMapper.selectUserIdByUsername(username);
        if (userId == null) {
            return Result.error("用户不存在");
        }

        // 查询用户地址列表
        List<UserAddress> addresses = userAddressMapper.selectList(
                new LambdaQueryWrapper<UserAddress>()
                        .eq(UserAddress::getUserId, userId)
                        .orderByDesc(UserAddress::getIsDefault)
                        .orderByDesc(UserAddress::getAddressId)
        );

        return Result.success("获取地址列表成功", addresses);
    }

    /**
     * 添加用户地址
     */
    @PostMapping
    public Result<UserAddress> addUserAddress(
            @RequestHeader(value = "Authorization", required = false) String tokenHeader,
            @RequestBody UserAddress userAddress) {
        // 验证JWT令牌
        if (tokenHeader == null || !tokenHeader.startsWith("Bearer ")) {
            return Result.error("用户未登录");
        }
        String token = tokenHeader.substring(7);
        if (token == null || token.isEmpty()) {
            return Result.error("用户未登录或令牌已过期");
        }

        // 使用JwtUtils提取用户名
        String username = jwtUtils.getUsernameFromToken(token);
        if (username == null) {
            return Result.error("用户未登录或令牌已过期");
        }

        // 根据用户名获取用户ID
        Long userId = userMapper.selectUserIdByUsername(username);
        if (userId == null) {
            return Result.error("用户不存在");
        }

        // 设置用户ID
        userAddress.setUserId(userId);
        
        // 如果设置为默认地址，将其他地址设为非默认
        if (userAddress.getIsDefault() != null && userAddress.getIsDefault() == 1) {
            // 将该用户的所有地址设为非默认
            UserAddress updateAddress = new UserAddress();
            updateAddress.setIsDefault(0);
            userAddressMapper.update(updateAddress,
                    new LambdaQueryWrapper<UserAddress>()
                            .eq(UserAddress::getUserId, userId)
            );
        }

        // 保存地址
        userAddressMapper.insert(userAddress);
        return Result.success("添加地址成功", userAddress);
    }

    /**
     * 更新用户地址
     */
    @PutMapping
    public Result<UserAddress> updateUserAddress(
            @RequestHeader(value = "Authorization", required = false) String tokenHeader,
            @RequestBody UserAddress userAddress) {
        // 验证JWT令牌
        if (tokenHeader == null || !tokenHeader.startsWith("Bearer ")) {
            return Result.error("用户未登录");
        }
        String token = tokenHeader.substring(7);
        if (token == null || token.isEmpty()) {
            return Result.error("用户未登录或令牌已过期");
        }

        // 使用JwtUtils提取用户名
        String username = jwtUtils.getUsernameFromToken(token);
        if (username == null) {
            return Result.error("用户未登录或令牌已过期");
        }

        // 根据用户名获取用户ID
        Long userId = userMapper.selectUserIdByUsername(username);
        if (userId == null) {
            return Result.error("用户不存在");
        }

        // 验证地址是否属于该用户
        UserAddress existingAddress = userAddressMapper.selectById(userAddress.getAddressId());
        if (existingAddress == null || !existingAddress.getUserId().equals(userId)) {
            return Result.error("地址不存在或无权修改");
        }

        // 如果设置为默认地址，将其他地址设为非默认
        if (userAddress.getIsDefault() != null && userAddress.getIsDefault() == 1) {
            // 将该用户的所有地址设为非默认
            UserAddress updateAddress = new UserAddress();
            updateAddress.setIsDefault(0);
            userAddressMapper.update(updateAddress,
                    new LambdaQueryWrapper<UserAddress>()
                            .eq(UserAddress::getUserId, userId)
            );
        }

        // 更新地址
        userAddressMapper.updateById(userAddress);
        return Result.success("更新地址成功", userAddress);
    }

    /**
     * 删除用户地址
     */
    @DeleteMapping("/{addressId}")
    public Result<Object> deleteUserAddress(
            @RequestHeader(value = "Authorization", required = false) String tokenHeader,
            @PathVariable Long addressId) {
        // 验证JWT令牌
        if (tokenHeader == null || !tokenHeader.startsWith("Bearer ")) {
            return Result.error("用户未登录");
        }
        String token = tokenHeader.substring(7);
        if (token == null || token.isEmpty()) {
            return Result.error("用户未登录或令牌已过期");
        }

        // 使用JwtUtils提取用户名
        String username = jwtUtils.getUsernameFromToken(token);
        if (username == null) {
            return Result.error("用户未登录或令牌已过期");
        }

        // 根据用户名获取用户ID
        Long userId = userMapper.selectUserIdByUsername(username);
        if (userId == null) {
            return Result.error("用户不存在");
        }

        // 验证地址是否属于该用户
        UserAddress existingAddress = userAddressMapper.selectById(addressId);
        if (existingAddress == null || !existingAddress.getUserId().equals(userId)) {
            return Result.error("地址不存在或无权删除");
        }

        // 删除地址
        userAddressMapper.deleteById(addressId);
        return Result.success("删除地址成功");
    }
    
    /**
     * 设置默认地址
     */
    @PutMapping("/{addressId}/default")
    public Result<Object> setDefaultAddress(
            @RequestHeader(value = "Authorization", required = false) String tokenHeader,
            @PathVariable Long addressId) {
        // 验证JWT令牌
        if (tokenHeader == null || !tokenHeader.startsWith("Bearer ")) {
            return Result.error("用户未登录");
        }
        String token = tokenHeader.substring(7);
        if (token == null || token.isEmpty()) {
            return Result.error("用户未登录或令牌已过期");
        }

        // 使用JwtUtils提取用户名
        String username = jwtUtils.getUsernameFromToken(token);
        if (username == null) {
            return Result.error("用户未登录或令牌已过期");
        }

        // 根据用户名获取用户ID
        Long userId = userMapper.selectUserIdByUsername(username);
        if (userId == null) {
            return Result.error("用户不存在");
        }

        // 验证地址是否属于该用户
        UserAddress existingAddress = userAddressMapper.selectById(addressId);
        if (existingAddress == null || !existingAddress.getUserId().equals(userId)) {
            return Result.error("地址不存在或无权修改");
        }

        // 将该用户的所有地址设为非默认
        UserAddress updateAddress = new UserAddress();
        updateAddress.setIsDefault(0);
        userAddressMapper.update(updateAddress,
                new LambdaQueryWrapper<UserAddress>()
                        .eq(UserAddress::getUserId, userId)
        );

        // 将指定地址设为默认
        UserAddress defaultAddress = new UserAddress();
        defaultAddress.setIsDefault(1);
        userAddressMapper.update(defaultAddress,
                new LambdaQueryWrapper<UserAddress>()
                        .eq(UserAddress::getAddressId, addressId)
        );

        return Result.success("设置默认地址成功");
    }
}
