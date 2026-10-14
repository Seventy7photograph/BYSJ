package bysj.pets.bec.utils;

import org.springframework.stereotype.Component;

/**
 * 用户自由文本的入库前处理。
 *
 * 说明清楚这一层的定位：**输出侧的转义才是主要防线**。前端用 Vue 渲染，
 * 默认转义所有插值，项目里没有任何 v-html，所以存储在库里的文本不会在网页上
 * 变成可执行标记。这里做的是纵深防御 —— 面向的不是网页，而是
 * Excel 导出、第三方客户端、以后可能出现的富文本渲染点。
 *
 * 因此这里**只剔除明确危险的模式**（script/iframe/事件处理器/javascript: 协议），
 * 不做 HTML 实体转义。转义会把 "24-70mm f/2.8 < 500g" 这种正常内容变成
 * "&lt;"，在 Vue 里再转义一次就是双重转义，用户看到的是乱码。
 */
@Component
public class TextSanitizer {

    private final XssProtectionUtil xssProtectionUtil;

    public TextSanitizer(XssProtectionUtil xssProtectionUtil) {
        this.xssProtectionUtil = xssProtectionUtil;
    }

    /** 清洗并裁剪长文本（商品描述、评价内容等）。 */
    public String clean(String input, int maxLength) {
        if (input == null) {
            return null;
        }
        String trimmed = input.trim();
        if (trimmed.isEmpty()) {
            return trimmed;
        }
        return xssProtectionUtil.sanitizeInput(trimmed, maxLength);
    }

    /** 清洗短文本（型号、标题、理由等），上限 255。 */
    public String cleanShort(String input) {
        return clean(input, 255);
    }
}
