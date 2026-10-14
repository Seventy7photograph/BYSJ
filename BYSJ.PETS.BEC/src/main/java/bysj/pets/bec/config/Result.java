package bysj.pets.bec.config;

import lombok.Data;

@Data
public class Result<T> {
    private int code; // 自定义状态码：200成功/500失败/400参数错误
    private String msg;
    private T data;

    // 静态构造方法
    public static <T> Result<T> success(T data) { // 增加带数据的成功方法
        Result<T> result = new Result<>();
        result.setCode(200);
        result.setMsg("操作成功");
        result.setData(data);
        return result;
    }

    public static <T> Result<T> success(String msg, T data) { // 增加带消息和数据的成功方法
        Result<T> result = new Result<>();
        result.setCode(200);
        result.setMsg(msg);
        result.setData(data);
        return result;
    }

    public static <T> Result<T> success(String msg) { // 增加只有消息的成功方法
        Result<T> result = new Result<>();
        result.setCode(200);
        result.setMsg(msg);
        result.setData(null);
        return result;
    }

    public static <T> Result<T> error(String msg) {
        Result<T> result = new Result<>();
        result.setCode(500);
        result.setMsg(msg);
        return result;
    }

    public static <T> Result<T> error(int code, String msg) {
        Result<T> result = new Result<>();
        result.setCode(code);
        result.setMsg(msg);
        return result;
    }

}
