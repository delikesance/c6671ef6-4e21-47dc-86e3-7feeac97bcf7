"""Generate the app-wide Material IconData -> Reicon name bridge.

The bridge keeps existing typed IconData parameters while AppIcon renders SVGs.
Run from the repository root after adding new app icons.
"""

from __future__ import annotations

import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parents[1]
APP = ROOT / "packages/app/lib"
PACKAGE = pathlib.Path.home() / ".pub-cache/hosted/pub.dev/reicon_flutter-1.0.1/lib/src/icons.dart"
OUTPUT = APP / "core/widgets/reicon_material_map.dart"

# Semantic equivalents for names that differ between Material and Reicon.
ALIASES = {
    'account_circle': 'userCircle', 'account_tree': 'nodes',
    'add_box': 'boxAdd', 'add_circle_outline': 'addCircle',
    'add_photo_alternate': 'imagePlus', 'add_reaction': 'chatPlus',
    'add_task': 'taskSquare', 'add_to_photos': 'images',
    'adjust': 'recordCircle', 'admin_panel_settings': 'shieldUser',
    'all_inclusive': 'infinite', 'alt_route': 'routing',
    'alternate_email': 'atSign', 'analytics': 'chartLine',
    'arrow_back': 'arrowLeft', 'arrow_downward': 'arrowDown',
    'arrow_drop_down': 'chevronDown', 'arrow_forward': 'arrowRight',
    'arrow_forward_ios': 'chevronRight', 'arrow_outward': 'arrowUpRight', 'arrow_right': 'arrowRight',
    'arrow_upward': 'arrowUp', 'article': 'documentText',
    'aspect_ratio': 'aspectRatioSquare', 'attach_file': 'paperclip',
    'auto_awesome': 'sparkles', 'auto_fix_high': 'magicWand',
    'auto_graph': 'graphUp', 'auto_stories': 'bookOpen',
    'autorenew': 'refresh', 'backup': 'cloudUpload',
    'badge': 'userId', 'bar_chart': 'chartBar',
    'block': 'userBlock', 'broken_image': 'imageMinus',
    'bug_report': 'searchBug', 'build': 'designtools',
    'calculate': 'calculator', 'calendar_today': 'calendarDay',
    'call_to_action': 'arrowSquare', 'camera_alt': 'camera',
    'campaign': 'bullhorn', 'cancel': 'xCircle',
    'casino': 'gamepad', 'category': 'category',
    'chat_bubble': 'chatRound', 'chat_bubble_outline': 'chatRound',
    'check_box': 'checkSquare', 'check_box_outline_blank': 'box',
    'check_circle_outline': 'checkCircle', 'circle': 'recordCircle',
    'clear': 'x', 'clear_all': 'listX', 'close': 'x',
    'cloud_done': 'cloudCheck', 'cloud_off': 'cloudX',
    'color_lens': 'palette', 'commit': 'branchUp',
    'content_copy': 'copy', 'content_paste_go': 'clipboard',
    'copy_all': 'copy', 'create_new_folder': 'folderAdd',
    'crop_square': 'box', 'dashboard': 'grid',
    'dashboard_customize': 'gridEdit', 'data_object': 'code',
    'dataset': 'database', 'delete': 'trash',
    'delete_forever': 'trash', 'delete_outline': 'trash',
    'delete_sweep': 'trash', 'description': 'fileText',
    'deselect': 'textSelect', 'developer_mode': 'codeSquare',
    'dns': 'server', 'download_for_offline': 'downloadSquare',
    'drag_handle': 'menu2', 'drag_indicator': 'menu',
    'drive_file_move': 'folderMove', 'dynamic_feed': 'list',
    'dynamic_form': 'listSquare', 'edit_attributes': 'edit',
    'edit_calendar': 'calendarEdit', 'edit_note': 'note',
    'edit_square': 'edit',
    'edit_notifications': 'notification', 'emoji_emotions': 'faceSmile',
    'error': 'alertCircle', 'error_outline': 'alertCircle',
    'exit_to_app': 'logout',
    'expand_less': 'chevronUp', 'expand_more': 'chevronDown',
    'extension': 'puzzlePiece', 'fact_check': 'clipboardCheck',
    'fiber_manual_record': 'recordCircle', 'filter_alt': 'filter',
    'filter_b_and_w': 'filter', 'filter_list': 'filters',
    'filter_none': 'filter', 'fit_screen': 'fullscreen',
    'flash_on': 'flash', 'folder_off': 'folderCross',
    'fork_right': 'branchDown', 'format_align_left': 'alignLeft',
    'format_indent_decrease': 'textalignLeft',
    'format_indent_increase': 'textalignRight',
    'format_list_numbered': 'orderedList', 'forum': 'messages',
    'functions': 'codeCircle', 'g_mobiledata': 'mobile',
    'gpp_bad': 'shieldX', 'groups': 'group',
    'headset_off': 'headset', 'hearing': 'earbuds',
    'hearing_disabled': 'earbudsCase', 'help_outline': 'helpCircle',
    'history_toggle_off': 'history', 'horizontal_rule': 'minus',
    'hourglass_empty': 'hourglass', 'hourglass_top': 'hourglass',
    'http': 'globe', 'hub': 'nodes', 'import_export': 'import',
    'info': 'circleInfo', 'info_outline': 'circleInfo',
    'input': 'arrowDoorIn',
    'insert_drive_file': 'file', 'insights': 'chartTrend',
    'inventory_2': 'archiveBox', 'invert_colors': 'droplet',
    'ios_share': 'share', 'javascript': 'code',
    'key_off': 'key', 'keyboard_arrow_down': 'chevronDown',
    'keyboard_arrow_up': 'chevronUp', 'label': 'tag',
    'lan': 'nodes', 'lightbulb_outline': 'lightbulb',
    'linear_scale': 'rowHorizontal', 'list_alt': 'checklistAlt',
    'lock_outline': 'lock', 'lock_reset': 'lockKeyhole',
    'loop': 'repeat', 'manage_accounts': 'userEdit',
    'manage_search': 'search', 'maps_ugc': 'messagePlus',
    'memory': 'cpu', 'menu_book': 'bookOpen',
    'menu_open': 'menu', 'merge_type': 'branchUp',
    'more_horiz': 'moreH', 'more_vert': 'more',
    'my_location': 'location', 'no_photography': 'cameraOff',
    'notifications_active': 'notificationBing',
    'numbers': 'hashtag', 'offline_bolt': 'bolt',
    'open_in_browser': 'window', 'open_in_new': 'windowExpandBottomRight',
    'paste': 'clipboard', 'pause_circle_outline': 'pauseCircle',
    'people_outline': 'people', 'person': 'user',
    'person_add': 'userAdd', 'person_add_alt_1': 'userAdd',
    'person_remove': 'userRemove', 'person_remove_alt_1': 'userRemove',
    'phone_android': 'mobile', 'photo_library': 'images',
    'play_arrow': 'play', 'play_circle_fill': 'playCircle',
    'play_circle_outline': 'playCircle', 'playlist_add': 'playlist',
    'playlist_add_check': 'listCheck', 'playlist_play': 'playlist',
    'playlist_remove': 'playRemove', 'power_settings_new': 'power',
    'preview': 'eye', 'privacy_tip': 'shieldCheck',
    'public': 'globe', 'push_pin': 'pin',
    'query_stats': 'chartLine', 'radio_button_checked': 'recordCircle',
    'radio_button_unchecked': 'recordCircle',
    'receipt_long': 'receiptText', 'remove': 'minus',
    'remove_circle': 'minusCircle',
    'replay': 'refresh', 'restart_alt': 'restart', 'restore': 'history',
    'restore_page': 'fileCheck', 'rocket_launch': 'rocket',
    'save_as': 'save', 'schedule': 'clock',
    'schedule_send': 'sendClock', 'school': 'graduationCap',
    'science': 'flask', 'segment': 'list',
    'select_all': 'textSelect', 'settings_voice': 'microphone',
    'short_text': 'text', 'show_chart': 'chartLine',
    'skip_previous': 'skipPrev', 'smart_button': 'cursorSquare',
    'smart_toy': 'cpu', 'space_bar': 'text',
    'speed': 'speedMid', 'star_border': 'star',
    'storage': 'database', 'style': 'palette',
    'subdirectory_arrow_right': 'arrowDownRight',
    'subscriptions': 'subscription', 'swap_horiz': 'arrowSwapHorizontal',
    'swap_vert': 'arrowsRotate', 'sync': 'refresh',
    'sync_alt': 'arrowSwapHorizontal', 'sync_problem': 'refreshCircle',
    'system_update': 'download', 'system_update_alt': 'download',
    'terminal': 'terminalSquare', 'text_fields': 'text',
    'textsms': 'messageText', 'timer_off': 'timer',
    'tips_and_updates': 'lightbulb', 'title': 'text',
    'toll': 'coins', 'touch_app': 'hand',
    'travel_explore': 'globalSearch', 'trending_flat': 'arrowRight',
    'tune': 'sliders', 'tv_off': 'videoOff',
    'update': 'refresh', 'upload_file': 'fileUp',
    'verified_user': 'shieldCheck',
    'vertical_align_bottom': 'alignBottom',
    'search': 'searchNormal2', 'settings': 'setting2',
    'vertical_align_top': 'alignTop', 'videocam': 'video',
    'videogame_asset': 'gamepad', 'view_agenda': 'listSquare',
    'view_list': 'list', 'view_stream': 'list',
    'visibility': 'eye', 'visibility_off': 'eyeOff',
    'vpn_key': 'key', 'vpn_key_off': 'key',
    'warning_amber': 'warning', 'waving_hand': 'hand',
    'webhook': 'link', 'widgets': 'widget',
    'wifi_find': 'wifi', 'workspace_premium': 'medal',
    'workspaces': 'grid', 'wrap_text': 'text',
    'zoom_in': 'searchZoomIn', 'zoom_out': 'searchZoomOut',
}


def base_name(material_name: str) -> str:
    return re.sub(r'_(outlined|outline|rounded|sharp|filled)$', '', material_name)


def camel(name: str) -> str:
    words = name.split('_')
    return words[0] + ''.join(word.title() for word in words[1:])


def main() -> None:
    package_source = PACKAGE.read_text()
    available = set(re.findall(r"^  '([A-Za-z0-9_]+)': r'''", package_source, re.M))
    sources = [p for p in APP.rglob('*.dart') if p != OUTPUT]
    material_names = sorted({
        name for source in sources
        for name in re.findall(r'\bIcons\.([A-Za-z0-9_]+)', source.read_text())
    })
    # After migration, the generated map is the inventory of existing usages.
    if not material_names and OUTPUT.exists():
        material_names = sorted(set(re.findall(r'Icons\.([A-Za-z0-9_]+):', OUTPUT.read_text())))
    invalid_aliases = {name: alias for name, alias in ALIASES.items() if alias not in available}
    if invalid_aliases:
        raise SystemExit(f'Unknown Reicon aliases: {invalid_aliases}')

    mapped = {}
    unresolved = []
    for name in material_names:
        base = base_name(name)
        target = ALIASES.get(base, camel(base))
        if target not in available:
            unresolved.append((name, target))
        else:
            mapped[name] = target
    if unresolved:
        raise SystemExit(f'Unmapped Material icons ({len(unresolved)}): {unresolved}')

    lines = [
        '// Generated by tools/generate_reicon_material_map.py. Do not edit.',
        "import 'package:flutter/material.dart';",
        "import 'package:reicon_flutter/reicon_flutter.dart';",
        '',
        'final Map<IconData, ({String outline, String filled})> reiconMaterialPaths = {',
    ]
    # Flutter aliases copy_outlined to content_copy_outlined (same IconData).
    lines.extend(
        f'  Icons.{name}: (outline: Reicon.outline.{target}, filled: Reicon.filled.{target}),'
        for name, target in mapped.items() if name != 'copy_outlined'
    )
    lines.extend(['};', '', 'final Set<IconData> reiconFilledMaterialIcons = const {};', ''])
    OUTPUT.write_text('\n'.join(lines))
    print(f'Generated {len(mapped)} Material -> Reicon mappings in {OUTPUT}')


if __name__ == '__main__':
    main()
