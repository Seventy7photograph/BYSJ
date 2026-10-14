package bysj.pets.bec.utils;

import javax.imageio.ImageIO;
import java.awt.*;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.Base64;
import java.util.Random;
import java.util.UUID;

public class CaptchaUtils {

    // 验证码字符集
    private static final String CODE_CHARACTERS = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    // 验证码长度
    private static final int CODE_LENGTH = 4;
    // 图片宽度
    private static final int WIDTH = 120;
    // 图片高度
    private static final int HEIGHT = 40;
    // 干扰线数量
    private static final int LINE_COUNT = 5;

    /**
     * 生成验证码
     * @return 包含验证码图片Base64和验证码文本的Map
     */
    public static CaptchaResult generateCaptcha() {
        // 生成随机验证码文本
        String code = generateCode();
        // 生成验证码图片
        String imageBase64 = generateImage(code);
        // 生成唯一标识
        String key = UUID.randomUUID().toString();

        return new CaptchaResult(key, code, imageBase64);
    }

    /**
     * 生成随机验证码文本
     */
    private static String generateCode() {
        Random random = new Random();
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < CODE_LENGTH; i++) {
            int index = random.nextInt(CODE_CHARACTERS.length());
            sb.append(CODE_CHARACTERS.charAt(index));
        }
        return sb.toString();
    }

    /**
     * 生成验证码图片并转为Base64
     */
    private static String generateImage(String code) {
        BufferedImage image = new BufferedImage(WIDTH, HEIGHT, BufferedImage.TYPE_INT_RGB);
        Graphics g = image.getGraphics();

        // 设置背景色
        g.setColor(Color.WHITE);
        g.fillRect(0, 0, WIDTH, HEIGHT);

        // 设置边框
        g.setColor(Color.LIGHT_GRAY);
        g.drawRect(0, 0, WIDTH - 1, HEIGHT - 1);

        // 绘制干扰线
        Random random = new Random();
        for (int i = 0; i < LINE_COUNT; i++) {
            int x1 = random.nextInt(WIDTH);
            int y1 = random.nextInt(HEIGHT);
            int x2 = random.nextInt(WIDTH);
            int y2 = random.nextInt(HEIGHT);
            g.setColor(new Color(random.nextInt(256), random.nextInt(256), random.nextInt(256)));
            g.drawLine(x1, y1, x2, y2);
        }

        // 绘制验证码
        g.setFont(new Font("Arial", Font.BOLD, 24));
        for (int i = 0; i < code.length(); i++) {
            g.setColor(new Color(random.nextInt(100), random.nextInt(100), random.nextInt(200)));
            g.drawString(String.valueOf(code.charAt(i)), 25 * i + 10, 28);
        }

        g.dispose();

        // 转为Base64
        try (ByteArrayOutputStream os = new ByteArrayOutputStream()) {
            ImageIO.write(image, "PNG", os);
            return "data:image/png;base64," + Base64.getEncoder().encodeToString(os.toByteArray());
        } catch (IOException e) {
            throw new RuntimeException("生成验证码图片失败", e);
        }
    }

    // 验证码结果封装类
    public static class CaptchaResult {
        private String key;
        private String code;
        private String image;

        public CaptchaResult(String key, String code, String image) {
            this.key = key;
            this.code = code;
            this.image = image;
        }

        // getter和setter
        public String getKey() { return key; }
        public void setKey(String key) { this.key = key; }
        public String getCode() { return code; }
        public void setCode(String code) { this.code = code; }
        public String getImage() { return image; }
        public void setImage(String image) { this.image = image; }
    }
}