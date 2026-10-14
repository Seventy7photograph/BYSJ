package bysj.pets.bec.utils;

import jakarta.mail.*;
import jakarta.mail.internet.InternetAddress;
import jakarta.mail.internet.MimeMessage;
import java.util.Properties;

public class EmailUtils {

    // QQ邮箱SMTP服务器
    private static final String SMTP_HOST = "smtp.qq.com";
    // 端口号
    private static final String SMTP_PORT = "587";
    // 发件人邮箱
    private static final String FROM_EMAIL = "3324879861@qq.com";
    // QQ邮箱授权码
    private static final String AUTH_CODE = "pktjxkzmsdmbchdj";

    public static void sendEmail(String toEmail, String subject, String content) throws Exception {
        // 配置邮件服务器
        Properties props = new Properties();
        props.put("mail.smtp.host", SMTP_HOST);
        props.put("mail.smtp.port", SMTP_PORT);
        props.put("mail.smtp.auth", "true");
        props.put("mail.smtp.starttls.enable", "true");

        // 创建会话
        Session session = Session.getInstance(props, new Authenticator() {
            @Override
            protected PasswordAuthentication getPasswordAuthentication() {
                return new PasswordAuthentication(FROM_EMAIL, AUTH_CODE);
            }
        });

        // 创建邮件
        Message message = new MimeMessage(session);
        message.setFrom(new InternetAddress(FROM_EMAIL));
        message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(toEmail));
        message.setSubject(subject);
        message.setText(content);

        // 发送邮件
        Transport.send(message);
    }
}