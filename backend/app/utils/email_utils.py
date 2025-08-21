from fastapi import BackgroundTasks
import smtplib
import ssl
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import os
import logging
import re
from dotenv import load_dotenv
from ..config import settings

load_dotenv()

SMTP_SERVER = os.getenv("SMTP_SERVER")
SMTP_PORT = int(os.getenv("SMTP_PORT"))
SMTP_USERNAME = os.getenv("SMTP_USERNAME")
SMTP_PASSWORD = os.getenv("SMTP_PASSWORD")
FROM_EMAIL = os.getenv("FROM_EMAIL")

TEST_EMAIL = os.getenv("TEST_EMAIL")


def send_invite_email_background(
    background_tasks: BackgroundTasks,
    to_email: str,
    invite_link: str,
    logger: logging.Logger,
    group_name: str = None
):
    logger.info(f"[send_invite_email_background] Scheduling invite email to {to_email} (group: {group_name})")
    subject = "You've been invited to join Wishful!"
    if group_name:
        message = f"You have been invited to join the group '<b>{group_name}</b>' on Wishful."
        cta_text = "Join Group"
    else:
        message = "You have been invited to join a wishlist on Wishful."
        cta_text = "Join Wishlist"
    html_body = build_email_html(
        subject=subject,
        message=message,
        cta_url=invite_link,
        cta_text=cta_text
    )
    background_tasks.add_task(send_email, to_email, subject, html_body, True)


def send_shared_email_background(
    background_tasks: BackgroundTasks,
    to_user_name: str,
    to_user_email: str,
    from_user_name: str,
    logger: logging.Logger
):
    to_user_name = to_user_name.capitalize()
    from_user_name = from_user_name.capitalize()
    logger.info(f"[send_shared_email_background] Scheduling share email to {to_user_email} from {from_user_name}.")
    subject = f"{from_user_name} has shared their wishlist with you!"
    message = f"Hi <b>{to_user_name}</b>,<br><br>{from_user_name} has shared their wishlist with you on Wishful!"
    html_body = build_email_html(
        subject=subject,
        message=message,
        cta_url=settings.WEBSITE_URL,
        cta_text="View Wishlist"
    )
    background_tasks.add_task(send_email, to_user_email, subject, html_body, logger, True)


def send_email(to_email: str, subject: str, body: str, logger: logging.Logger, is_html: bool = False):
    from .logger import logger
    if not is_valid_email(to_email):
        logger.error(f"[send_email] Invalid email address: {to_email}")
        return
    logger.info(f"[send_email] Sending email to {to_email} with subject '{subject}'")
    msg = MIMEMultipart()
    msg["From"] = FROM_EMAIL
    msg["To"] = to_email
    msg["Subject"] = subject
    if is_html:
        msg.attach(MIMEText(body, "html"))
    else:
        msg.attach(MIMEText(body, "plain"))

    context = ssl.create_default_context()

    try:
        with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
            server.ehlo()
            server.starttls(context=context)
            server.ehlo()
            server.login(SMTP_USERNAME, SMTP_PASSWORD)
            server.sendmail(FROM_EMAIL, to_email, msg.as_string())
    except Exception as e:
        print(f"Failed to send email: {e}")


# Helper to build a styled HTML email
def build_email_html(subject: str, message: str, cta_url: str = None, cta_text: str = None) -> str:
    logo_url = f"{settings.WEBSITE_URL}/static/logo.png"  # Adjust path as needed
    website_url = settings.WEBSITE_URL
    return f"""
    <html>
    <body style='background:#f7f7fa;padding:0;margin:0;font-family:sans-serif;'>
        <div style='max-width:480px;margin:40px auto;background:#fff;border-radius:8px;box-shadow:0 2px 8px #0001;padding:32px;'>
            <div style='text-align:center;margin-bottom:24px;'>
                <a href='{website_url}'><img src='{logo_url}' alt='Wishful Logo' style='height:48px;'/></a>
            </div>
            <h2 style='color:#4a4a4a;text-align:center;margin-bottom:24px;'>{subject}</h2>
            <div style='font-size:16px;color:#333;margin-bottom:32px;'>{message}</div>
            {f"<div style='text-align:center;margin-bottom:32px;'><a href='{cta_url}' style='background:#6c63ff;color:#fff;text-decoration:none;padding:12px 32px;border-radius:6px;font-weight:bold;font-size:16px;display:inline-block;'>{cta_text}</a></div>" if cta_url and cta_text else ''}
            <div style='color:#888;font-size:14px;margin-top:32px;'>
                Best wishes,<br>
                <b>The Wishful Team</b>
            </div>
        </div>
        <div style='text-align:center;color:#aaa;font-size:12px;margin-top:16px;'>
            <a href='{website_url}' style='color:#aaa;text-decoration:none;'>Visit Wishful</a>
        </div>
    </body>
    </html>
    """


def is_valid_email(email: str) -> bool:
    """Return True if email is valid, else False."""
    pattern = r"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"
    return re.match(pattern, email) is not None


if __name__ == "__main__":
    from .logger import logger
    # Test HTML email
    test_html = build_email_html(
        subject="You've been invited to join Wishful!",
        message="This is a test invite email.",
        cta_url="https://wishful.app/join",
        cta_text="Join Now"
    )
    send_email(TEST_EMAIL, "You've been invited to join Wishful", test_html, logger, True)
