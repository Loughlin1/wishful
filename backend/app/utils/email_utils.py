from fastapi import BackgroundTasks
import smtplib
import ssl
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import os
import traceback
from dotenv import load_dotenv

load_dotenv()

SMTP_SERVER = os.getenv("SMTP_SERVER")
SMTP_PORT = int(os.getenv("SMTP_PORT"))
SMTP_USERNAME = os.getenv("SMTP_USERNAME")
SMTP_PASSWORD = os.getenv("SMTP_PASSWORD")
FROM_EMAIL = os.getenv("FROM_EMAIL")

TEST_EMAIL = os.getenv("TEST_EMAIL")


def send_invite_email_background(background_tasks: BackgroundTasks, to_email: str, invite_link: str, group_name: str = None):
    from .logger import logger
    logger.info(f"[send_invite_email_background] Scheduling invite email to {to_email} (group: {group_name})")
    subject = f"You've been invited to join Wishful!"
    if group_name:
        body = f"You have been invited to join the group '{group_name}' on Wishful. Click here to join: {invite_link}"
    else:
        body = f"You have been invited to join a wishlist on Wishful. Click here to join: {invite_link}"
    background_tasks.add_task(send_email, to_email, subject, body)


def send_email(to_email: str, subject: str, body: str):
    from .logger import logger
    logger.info(f"[send_email] Sending email to {to_email} with subject '{subject}'")
    msg = MIMEMultipart()
    msg["From"] = FROM_EMAIL
    msg["To"] = to_email
    msg["Subject"] = subject
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


if __name__ == "__main__":
    send_email(TEST_EMAIL, "You've been invited to join Wishful", "Hello! Testing 123.")
