package bysj.pets.bec.config;

import bysj.pets.bec.config.Result;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.servlet.NoHandlerFoundException;

import java.util.stream.Collectors;
import lombok.extern.slf4j.Slf4j;

/**
 * 全局异常处理器，统一处理所有异常
 */
@RestControllerAdvice
@Slf4j
public class GlobalExceptionHandler {
    
    /**
     * 处理访问拒绝异常
     */
    @ExceptionHandler(AccessDeniedException.class)
    @ResponseStatus(HttpStatus.FORBIDDEN)
    public Result<Object> handleAccessDeniedException(AccessDeniedException e) {
        return Result.error(403, "权限不足");
    }
    
    /**
     * 处理认证异常
     */
    @ExceptionHandler(AuthenticationException.class)
    @ResponseStatus(HttpStatus.UNAUTHORIZED)
    public Result<Object> handleAuthenticationException(AuthenticationException e) {
        return Result.error(401, "认证失败，请重新登录");
    }
    
    /**
     * 处理运行时异常
     */
    @ExceptionHandler(RuntimeException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public Result<Object> handleRuntimeException(RuntimeException e) {
        // 日志记录
        log.error("运行时异常: {}", e.getMessage(), e);
        return Result.error(e.getMessage());
    }
    
    /**
     * 处理方法参数验证异常
     */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public Result<Object> handleMethodArgumentNotValidException(MethodArgumentNotValidException e) {
        // 提取所有验证错误信息
        String errorMsg = e.getBindingResult().getFieldErrors()
                .stream()
                .map(fieldError -> fieldError.getField() + ": " + fieldError.getDefaultMessage())
                .collect(Collectors.joining("; "));
        return Result.error(400, errorMsg);
    }
    
    /**
     * 处理404异常
     */
    @ExceptionHandler(NoHandlerFoundException.class)
    @ResponseStatus(HttpStatus.NOT_FOUND)
    public Result<Object> handleNoHandlerFoundException(NoHandlerFoundException e) {
        return Result.error(404, "请求的接口不存在");
    }

    /**
     * 静态资源不存在（例如引用了已删除的商品图）。
     *
     * Spring 6.1 起，静态资源未命中抛的是 NoResourceFoundException，
     * 它不在上面的 NoHandlerFoundException 分支里，会掉进兜底的 500 处理 ——
     * 于是一个"文件没了"被报成"服务器内部错误"。这里明确回 404。
     */
    @ExceptionHandler(org.springframework.web.servlet.resource.NoResourceFoundException.class)
    @ResponseStatus(HttpStatus.NOT_FOUND)
    public Result<Object> handleNoResourceFoundException(
            org.springframework.web.servlet.resource.NoResourceFoundException e) {
        return Result.error(404, "请求的资源不存在");
    }
    
    /**
     * 处理所有其他异常
     */
    @ExceptionHandler(Exception.class)
    @ResponseStatus(HttpStatus.INTERNAL_SERVER_ERROR)
    public Result<Object> handleException(Exception e) {
        // 日志记录
        log.error("未捕获异常: {}", e.getMessage(), e);
        return Result.error(500, "服务器内部错误，请稍后重试");
    }
}
