package bysj.pets.bec.handler;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.ibatis.type.BaseTypeHandler;
import org.apache.ibatis.type.JdbcType;
import org.apache.ibatis.type.MappedJdbcTypes;
import org.apache.ibatis.type.MappedTypes;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.sql.CallableStatement;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Collections;
import java.util.List;
import java.util.Map;

/**
 * 通用JSON类型处理器，支持将数据库JSON字段转换为Java对象（List/Map等）
 */
@MappedJdbcTypes(JdbcType.VARCHAR)
@MappedTypes({List.class, Map.class, List.class})
public class CustomJacksonTypeHandler extends BaseTypeHandler<Object> {

    private static final Logger logger = LoggerFactory.getLogger(CustomJacksonTypeHandler.class);
    public static final ObjectMapper OBJECT_MAPPER = new ObjectMapper()
            .configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false)
            .configure(DeserializationFeature.ACCEPT_SINGLE_VALUE_AS_ARRAY, true);

    @Override
    public void setNonNullParameter(PreparedStatement ps, int i, Object parameter, JdbcType jdbcType) throws SQLException {
        try {
            String json = OBJECT_MAPPER.writeValueAsString(parameter);
            ps.setString(i, json);
        } catch (Exception e) {
            logger.error("JSON序列化失败，参数: {}", parameter, e);
            throw new SQLException("JSON序列化失败", e);
        }
    }

    @Override
    public Object getNullableResult(ResultSet rs, String columnName) throws SQLException {
        String json = rs.getString(columnName);
        return parseJson(json, getTargetType());
    }

    @Override
    public Object getNullableResult(ResultSet rs, int columnIndex) throws SQLException {
        String json = rs.getString(columnIndex);
        return parseJson(json, getTargetType());
    }

    @Override
    public Object getNullableResult(CallableStatement cs, int columnIndex) throws SQLException {
        String json = cs.getString(columnIndex);
        return parseJson(json, getTargetType());
    }

    /**
     * 解析JSON字符串为目标类型对象
     */
    private Object parseJson(String json, Class<?> targetType) {
        if (json == null || json.trim().isEmpty() || "null".equals(json.trim())) {
            return getDefaultValue(targetType);
        }

        try {
            if (List.class.isAssignableFrom(targetType)) {
                // 处理List类型（默认List<String>，如需复杂类型可扩展TypeReference）
                return OBJECT_MAPPER.readValue(json, new TypeReference<List<Object>>() {});
            } else if (Map.class.isAssignableFrom(targetType)) {
                // 处理Map类型
                return OBJECT_MAPPER.readValue(json, new TypeReference<Map<String, Object>>() {});
            } else {
                // 处理自定义对象类型
                return OBJECT_MAPPER.readValue(json, targetType);
            }
        } catch (Exception e) {
            logger.error("JSON反序列化失败，目标类型: {}, JSON内容: {}", targetType.getName(), json, e);
            // JSON解析失败时返回默认值，避免抛出异常导致400错误
            return getDefaultValue(targetType);
        }
    }

    /**
     * 获取目标类型（实际使用时可能需要通过构造函数传入，此处简化处理）
     */
    private Class<?> getTargetType() {
        // 注意：实际应用中需根据具体场景获取目标类型，这里为简化示例返回Object
        // 推荐实现方式：通过构造函数传入目标TypeReference
        return Object.class;
    }

    /**
     * 获取默认值
     */
    private Object getDefaultValue(Class<?> targetType) {
        if (List.class.isAssignableFrom(targetType)) {
            return Collections.emptyList();
        } else if (Map.class.isAssignableFrom(targetType)) {
            return Collections.emptyMap();
        } else {
            return null;
        }
    }
}
