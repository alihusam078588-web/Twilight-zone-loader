import discord
import requests # Used to send data to the webhook

TOKEN = '06bab40a4dca2cb46c99950d0d62a7a287a958af1d216726635b64595b84a231'
WEBHOOK_URL = 'https://discord.com/api/webhooks/1453430027491479754/yiHEHCJa35N2zTS7RGuw41deIn9INJPsyBl8dsjQlrGNL4E-4b_-QeEWDd-m82fcSRPA'

intents = discord.Intents.default()
intents.messages = True
intents.message_content = True # Required to see the text of the message

client = discord.Client(intents=intents)

@client.event
async def on_ready():
    print(f'Logged in as {client.user}')

@client.event
async def on_message_edit(before, after):
    # Ignore bot messages to avoid loops
    if before.author.bot:
        return

    # Create the log message
    log_data = {
        "content": f"**{before.author}** edited a message:\n**From:** {before.content}\n**To:** {after.content}"
    }

    # Send to webhook
    response = requests.post(https://discord.com/api/webhooks/1453430027491479754/yiHEHCJa35N2zTS7RGuw41deIn9INJPsyBl8dsjQlrGNL4E-4b_-QeEWDd-m82fcSRPA, json=log_data)
    if response.status_code == 204:
        print("Log sent successfully.")

client.run(06bab40a4dca2cb46c99950d0d62a7a287a958af1d216726635b64595b84a231)
