import os
import requests
import time
from urllib.parse import urlparse

# 独立代理配置（仅限此脚本使用）
SCRIPT_PROXY = os.getenv('SCRIPT_PROXY')  # 使用独立环境变量名

GIST_ID = os.getenv('GIST_ID')
GIST_API_URL = f'https://api.github.com/gists/{GIST_ID}'
GITHUB_TOKEN = os.getenv('GITHUB_TOKEN')
config_file_path = 'clash_config.yaml'

def create_session():
    """创建带代理配置的会话"""
    session = requests.Session()
    
    if SCRIPT_PROXY:
        # 自动识别代理协议
        parsed = urlparse(SCRIPT_PROXY)
        
        # 根据协议类型设置代理字典
        if parsed.scheme in ['socks5', 'socks5h']:
            session.proxies = {'https': SCRIPT_PROXY}
        elif parsed.scheme in ['http', 'https']:
            session.proxies = {
                'http': SCRIPT_PROXY,
                'https': SCRIPT_PROXY
            }
        print(f"Using proxy: {SCRIPT_PROXY}")
    
    return session

def upload_gist(max_retries=3, retry_delay=5):
    with open(config_file_path, 'r') as file:
        content = file.read()

    gist_data = {
        'files': {
            'clash_config.yaml': {
                'content': content
            }
        }
    }

    headers = {
        'Authorization': f'token {GITHUB_TOKEN}',
        'Accept': 'application/vnd.github.v3+json'
    }

    session = create_session()
    
    for attempt in range(max_retries):
        try:
            response = session.patch(
                GIST_API_URL,
                json=gist_data,
                headers=headers,
                timeout=10  # 添加超时控制
            )
            response.raise_for_status()
            print('Gist updated successfully:', response.json()['html_url'])
            return
        except requests.exceptions.RequestException as e:
            print(f"Attempt {attempt + 1} failed: {e}")
            if attempt < max_retries - 1:
                print(f"Retrying in {retry_delay} seconds...")
                time.sleep(retry_delay)
            else:
                print(f"Failed to update Gist after {max_retries} attempts.")

if __name__ == '__main__':
    # 代理连接测试
    try:
        test_session = create_session()
        test_response = test_session.get('https://api.github.com', timeout=5)
        print("Proxy test passed" if test_response.ok else "Proxy test failed")
    except Exception as e:
        print(f"Proxy test error: {e}")

    upload_gist()