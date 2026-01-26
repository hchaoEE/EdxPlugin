#!/usr/bin/env python3
"""
EDX Plugin 服务器启动脚本
用于启动EDA工具REST API服务
"""

import sys
import os
import argparse
import logging
import time
import threading

# 添加项目根目录到Python路径
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from config import *

def setup_logging(log_level=logging.INFO):
    """设置日志记录"""
    # 创建tmp目录
    tmp_dir = os.path.join(DEFAULT_CONFIG.get('edx_tmp'), 'logs')
    os.makedirs(tmp_dir, exist_ok=True)
    log_file_path = os.path.join(tmp_dir, 'server_startup.log')

    logging.basicConfig(
        level=log_level,
        format='%(asctime)s %(levelname)s %(name)s [%(filename)s:%(lineno)d] %(message)s',
        handlers=[
            logging.FileHandler(log_file_path),
            logging.StreamHandler(sys.stdout)
        ]
    )

def check_dependencies():
    """检查必要的依赖"""
    logger = logging.getLogger(__name__)
    logger.info("检查依赖项...")

    try:
        import flask
        logger.info(f"Flask版本: {flask.__version__}")
    except ImportError:
        logger.error("Flask未安装，请运行 'pip install -r requirements.txt'")
        return False

    try:
        # 尝试导入我们的配置文件
        from config import DEFAULT_CONFIG
        logger.info("配置文件加载成功")
    except ImportError as e:
        logger.error(f"无法导入配置文件: {e}")
        return False

    return True

def start_server(host='0.0.0.0', port=5000, debug=False):
    """启动服务器"""
    logger = logging.getLogger(__name__)
    logger.info(f"准备启动服务器 - 主机: {host}, 端口: {port}, 调试模式: {debug}")

    try:
        from main import app
        logger.info("Flask应用加载成功")

        # 启动服务器
        logger.info(f"正在启动服务器，地址: {host}:{port}")
        app.run(host=host, port=port, debug=debug)

    except Exception as e:
        logger.error(f"启动服务器时出错: {e}")
        import traceback
        logger.error(traceback.format_exc())
        return False

    return True

def main():
    parser = argparse.ArgumentParser(description='EDX Plugin 服务器启动脚本')
    parser.add_argument('--host', default='0.0.0.0', help='服务器主机地址 (默认: 0.0.0.0)')
    parser.add_argument('--port', type=int, default=5000, help='服务器端口 (默认: 5000)')
    parser.add_argument('--debug', action='store_true', help='启用调试模式')
    parser.add_argument('--log-level', default='INFO', choices=['DEBUG', 'INFO', 'WARNING', 'ERROR'],
                       help='日志级别 (默认: INFO)')

    args = parser.parse_args()

    # 设置日志
    log_level = getattr(logging, args.log_level.upper())
    setup_logging(log_level)
    logger = logging.getLogger(__name__)

    logger.info("=" * 50)
    logger.info("启动EDX Plugin EDA工具REST API服务")
    logger.info(f"参数 - 主机: {args.host}, 端口: {args.port}, 调试: {args.debug}")
    logger.info("=" * 50)

    # 检查依赖
    if not check_dependencies():
        logger.error("依赖检查失败，退出...")
        sys.exit(1)

    logger.info("依赖检查通过")

    # 启动服务器
    logger.info("开始启动服务器...")
    # 使用县城运行start_server
    flask_thread = threading.Thread(target=start_server, args=(args.host, args.port, args.debug), daemon=True)
    flask_thread.start()
    logger.info("服务器启动完成...")
    # edx_tmp目录下如果有command_reader_stop文件，则进程退出
    while True:
        edx_tmp_dir = DEFAULT_CONFIG.get('edx_tmp')
        if os.path.exists(os.path.join(edx_tmp_dir, 'command_reader_stop')):
            logger.info("检测到command_reader_stop文件，进程退出...")
            sys.exit(0)
        time.sleep(1)

if __name__ == '__main__':
    main()