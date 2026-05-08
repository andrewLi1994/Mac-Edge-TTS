#!/usr/bin/env python3
"""
Mac-Edge-TTS 语言检测模块
策略：Unicode 字符集优先判断 + langdetect 兜底（仅用于拉丁语系细分）
"""
import sys
import re
import unicodedata


def detect_by_script(text):
    """
    基于 Unicode 码点直接判断语言。
    先去除 ASCII 字符（英文路径、技术术语等噪声），
    再统计剩余非 ASCII 字母的字符集分布。
    """
    # 去除所有 ASCII 字符：英文字母、数字、路径符号都是噪声
    clean = re.sub(r'[\x00-\x7F]', '', text)

    counts = {
        'cjk': 0,
        'hiragana': 0,
        'katakana': 0,
        'hangul': 0,
        'cyrillic': 0,
        'arabic': 0,
        'thai': 0,
        'latin_ext': 0,  # 扩展拉丁（越南语、法语等）
    }
    total = 0

    for ch in clean:
        if not unicodedata.category(ch).startswith('L'):
            continue
        total += 1
        cp = ord(ch)

        # CJK 统一汉字（中文、日文汉字共用）
        if cp in range(0x4E00, 0xA000) or cp in range(0x3400, 0x4DC0) or cp in range(0xF900, 0xFB00):
            counts['cjk'] += 1
        # 日文平假名
        elif cp in range(0x3040, 0x30A0):
            counts['hiragana'] += 1
        # 日文片假名
        elif cp in range(0x30A0, 0x3100):
            counts['katakana'] += 1
        # 韩文音节
        elif cp in range(0xAC00, 0xD7B0) or cp in range(0x1100, 0x1200):
            counts['hangul'] += 1
        # 西里尔字母（俄语等）
        elif cp in range(0x0400, 0x0500):
            counts['cyrillic'] += 1
        # 阿拉伯字母
        elif cp in range(0x0600, 0x0700):
            counts['arabic'] += 1
        # 泰文
        elif cp in range(0x0E00, 0x0E80):
            counts['thai'] += 1
        # 扩展拉丁（0x00C0-0x024F：越南语、法语、德语变音符等）
        elif cp in range(0x00C0, 0x0250):
            counts['latin_ext'] += 1

    if total == 0:
        # 纯 ASCII 文本，交给 langdetect
        return None

    r = {k: v / total for k, v in counts.items()}

    # ⚡ 关键优先级设计：
    # 1. 日文最先判断：中文里绝对不含平/片假名，有假名就一定是日文
    #    （即使文中汉字很多，假名 > 10% 也足以判定为日文）
    if r['hiragana'] + r['katakana'] > 0.1:
        return 'ja'
    # 2. 其余非拉丁文字靠字符集占比判断（>= 30% 阈值）
    if r['cjk'] >= 0.3:
        return 'zh-cn'
    if r['hangul'] >= 0.3:
        return 'ko'
    if r['cyrillic'] >= 0.3:
        return 'ru'
    if r['arabic'] >= 0.3:
        return 'ar'
    if r['thai'] >= 0.3:
        return 'th'

    # 只有扩展拉丁字符 → 仍需 langdetect 细分（越南/法语/德语等）
    return None


# 语言代码 → Edge TTS 声音名称映射
VOICE_MAP = {
    'zh-cn': 'zh-CN-XiaoxiaoNeural',
    'zh-tw': 'zh-TW-HsiaoChenNeural',
    'en':    'en-US-AriaNeural',
    'ja':    'ja-JP-NanamiNeural',
    'ko':    'ko-KR-SunHiNeural',
    'fr':    'fr-FR-DeniseNeural',
    'de':    'de-DE-KatjaNeural',
    'es':    'es-ES-ElviraNeural',
    'it':    'it-IT-ElsaNeural',
    'ru':    'ru-RU-SvetlanaNeural',
    'pt':    'pt-BR-FranciscaNeural',
    'vi':    'vi-VN-HoaiMyNeural',
    'ar':    'ar-SA-ZariyahNeural',
    'th':    'th-TH-PremwadeeNeural',
}


def main():
    if len(sys.argv) < 2:
        print('ERROR')
        return

    text = sys.argv[1]

    try:
        lang = detect_by_script(text)

        # fallback：用 langdetect 细分拉丁语系
        if lang is None:
            from langdetect import detect as ld_detect, DetectorFactory
            DetectorFactory.seed = 0
            lang = ld_detect(text)

        # zh-cn / zh-tw 都用 zh-cn（简繁判断用同一语音即可）
        if lang and lang.startswith('zh'):
            print(VOICE_MAP.get('zh-cn', 'ERROR'))
        elif lang:
            print(VOICE_MAP.get(lang, 'ERROR'))
        else:
            print('ERROR')

    except Exception:
        print('ERROR')


if __name__ == '__main__':
    main()
