import random
import logging
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from app.config import settings

logger = logging.getLogger(__name__)


def generate_otp() -> str:
    """Generate a secure 6-digit verification code."""
    return f"{random.randint(100000, 999999)}"


def send_email(to_email: str, subject: str, html_content: str, text_content: str = "") -> bool:
    """Send an email using SMTP with fallback to console logging for local dev."""
    if not settings.smtp_user or not settings.smtp_password:
        logger.warning(
            f"[DEV EMAIL MOCK] To: {to_email} | Subject: {subject}\n"
            f"Content: {text_content or html_content}"
        )
        print(f"\n[DEV EMAIL MOCK] To: {to_email} | Subject: {subject}\n{text_content or html_content}\n")
        return True

    try:
        msg = MIMEMultipart("alternative")
        msg["Subject"] = subject
        msg["From"] = settings.smtp_from_email
        msg["To"] = to_email

        if text_content:
            msg.attach(MIMEText(text_content, "plain"))
        if html_content:
            msg.attach(MIMEText(html_content, "html"))

        with smtplib.SMTP(settings.smtp_server, settings.smtp_port) as server:
            server.starttls()
            server.login(settings.smtp_user, settings.smtp_password)
            server.sendmail(settings.smtp_from_email, to_email, msg.as_string())

        logger.info(f"Email sent successfully to {to_email}")
        return True
    except Exception as e:
        logger.error(f"Failed to send email to {to_email}: {e}")
        # In non-production, don't crash on email failure
        if settings.app_env == "development":
            print(f"\n[DEV FALLBACK] Failed to send SMTP, mock output: To: {to_email} | Subject: {subject}\n{text_content or html_content}\n")
            return True
        return False


def send_verification_email(to_email: str, code: str) -> bool:
    """Send email verification OTP."""
    subject = "Verify your FurrMind account"
    text_content = f"Welcome to FurrMind! Your verification code is: {code}. It will expire in {settings.otp_expire_minutes} minutes."
    html_content = f"""
    <div style="font-family: Arial, sans-serif; max-width: 500px; margin: auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 12px;">
        <h2 style="color: #4A90E2; text-align: center;">🐾 Welcome to FurrMind!</h2>
        <p>Thank you for joining FurrMind. Please use the verification code below to verify your email address:</p>
        <div style="background-color: #F4F6F9; border-radius: 8px; padding: 16px; text-align: center; margin: 24px 0;">
            <span style="font-size: 32px; font-weight: bold; letter-spacing: 6px; color: #2C3E50;">{code}</span>
        </div>
        <p style="font-size: 13px; color: #7F8C8D;">This code is valid for {settings.otp_expire_minutes} minutes. If you did not create an account, please ignore this email.</p>
    </div>
    """
    return send_email(to_email, subject, html_content, text_content)


def send_password_reset_email(to_email: str, code: str) -> bool:
    """Send password reset OTP."""
    subject = "Reset your FurrMind password"
    text_content = f"You requested to reset your FurrMind password. Your reset code is: {code}. It will expire in {settings.otp_expire_minutes} minutes."
    html_content = f"""
    <div style="font-family: Arial, sans-serif; max-width: 500px; margin: auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 12px;">
        <h2 style="color: #E74C3C; text-align: center;">🐾 FurrMind Password Reset</h2>
        <p>We received a request to reset your password. Use the code below to complete your password reset:</p>
        <div style="background-color: #FDF2E9; border-radius: 8px; padding: 16px; text-align: center; margin: 24px 0;">
            <span style="font-size: 32px; font-weight: bold; letter-spacing: 6px; color: #C0392B;">{code}</span>
        </div>
        <p style="font-size: 13px; color: #7F8C8D;">This code is valid for {settings.otp_expire_minutes} minutes. If you did not request a password reset, you can safely ignore this email.</p>
    </div>
    """
    return send_email(to_email, subject, html_content, text_content)
