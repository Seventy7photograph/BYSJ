package bysj.pets.bec.utils;

import bysj.pets.bec.entity.SysLog;
import bysj.pets.bec.mapper.SysLogMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;

@Component
public class LogUtils {
    
    @Autowired
    private SysLogMapper sysLogMapper;
    
    /**
     * 记录操作日志
     * @param userId 用户ID
     * @param operation 操作描述
     * @param module 操作模块
     */
    public void recordOperationLog(Long userId, String operation, String module) {
        SysLog sysLog = new SysLog();
        sysLog.setUserId(userId);
        sysLog.setLogType(1); // 1-操作日志
        sysLog.setOperation(operation);
        sysLog.setModule(module);
        sysLog.setIp("127.0.0.1"); // 暂时使用默认IP
        sysLog.setCreateTime(LocalDateTime.now());
        sysLogMapper.insert(sysLog);
    }
    
    /**
     * 记录错误日志
     * @param userId 用户ID
     * @param errorMsg 错误信息
     * @param module 操作模块
     */
    public void recordErrorLog(Long userId, String errorMsg, String module) {
        SysLog sysLog = new SysLog();
        sysLog.setUserId(userId);
        sysLog.setLogType(2); // 2-错误日志
        sysLog.setOperation("操作失败");
        sysLog.setModule(module);
        sysLog.setErrorMsg(errorMsg);
        sysLog.setIp("127.0.0.1"); // 暂时使用默认IP
        sysLog.setCreateTime(LocalDateTime.now());
        sysLogMapper.insert(sysLog);
    }
}
