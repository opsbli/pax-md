#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

fn main() {
    // 静默安装模式（/S）：无界面完成安装后直接退出，供无人值守/商店分发使用
    if let Some(code) = pax_md_installer_lib::detect_silent_install() {
        std::process::exit(code);
    }
    pax_md_installer_lib::run()
}
