lingmo_install_package(activitybar org.kde.lingmo.activitybar)
add_subdirectory(icon)

lingmo_install_package(analog-clock org.kde.lingmo.analogclock)
lingmo_install_package(lock_logout org.kde.lingmo.lock_logout)
lingmo_install_package(manage-inputmethod org.kde.lingmo.manage-inputmethod)

add_subdirectory(appmenu)
add_subdirectory(systemmonitor)
add_subdirectory(calendar)
add_subdirectory(devicenotifier)
add_subdirectory(digital-clock)
add_subdirectory(keyboardindicator)
add_subdirectory(kicker)
add_subdirectory(mediacontroller)
add_subdirectory(panelspacer)
add_subdirectory(cameraindicator)
lingmo_install_package(clipboard org.kde.lingmo.clipboard)

add_subdirectory(notifications)
add_subdirectory(systemtray)
