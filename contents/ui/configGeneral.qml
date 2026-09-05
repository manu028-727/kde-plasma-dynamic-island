import QtQuick
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami

KCM.SimpleKCM {
    id: configPage

    property alias cfg_mediaActivityEnabled: mediaActivityEnabled.checked
    property alias cfg_notificationActivityEnabled: notificationActivityEnabled.checked
    property alias cfg_jobActivityEnabled: jobActivityEnabled.checked
    property alias cfg_keyboardLayoutActivityEnabled: keyboardLayoutActivityEnabled.checked
    property alias cfg_notificationShowImages: notificationShowImages.checked
    property alias cfg_notificationBodyCharacterLimit: notificationBodyCharacterLimit.value
    property alias cfg_notificationBodyLineLimit: notificationBodyLineLimit.value
    property alias cfg_notificationPopupDurationSeconds: notificationPopupDurationSeconds.value
    property alias cfg_ongoingPopupDurationSeconds: ongoingPopupDurationSeconds.value

    Kirigami.FormLayout {
        PlasmaCheckBox {
            id: mediaActivityEnabled

            Kirigami.FormData.label: i18n("Activity providers:")
            text: i18n("Music playback")
        }

        PlasmaCheckBox {
            id: notificationActivityEnabled

            text: i18n("Notifications")
        }

        PlasmaCheckBox {
            id: jobActivityEnabled

            text: i18n("Downloads and jobs")
        }

        PlasmaCheckBox {
            id: keyboardLayoutActivityEnabled

            text: i18n("Keyboard layout announcements")
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
        }

        PlasmaCheckBox {
            id: notificationShowImages

            Kirigami.FormData.label: i18n("Notifications:")
            text: i18n("Show images and thumbnails")
        }

        PlasmaSpinBox {
            id: notificationBodyCharacterLimit

            Kirigami.FormData.label: i18n("Body length:")
            from: 40
            to: 1000
            stepSize: 20
            editable: true
            textFromValue: (value, locale) => i18np("%1 character", "%1 characters", value)
            valueFromText: (text, locale) => {
                const parsed = parseInt(text);
                return isFinite(parsed) ? Math.max(from, Math.min(to, parsed)) : from;
            }
        }

        PlasmaSpinBox {
            id: notificationBodyLineLimit

            Kirigami.FormData.label: i18n("Preview lines:")
            from: 1
            to: 6
            editable: true
        }

        PlasmaSpinBox {
            id: notificationPopupDurationSeconds

            Kirigami.FormData.label: i18n("Popup duration:")
            from: 2
            to: 15
            textFromValue: (value, locale) => i18np("%1 second", "%1 seconds", value)
            valueFromText: (text, locale) => {
                const parsed = parseInt(text);
                return isFinite(parsed) ? Math.max(from, Math.min(to, parsed)) : from;
            }
        }

        PlasmaSpinBox {
            id: ongoingPopupDurationSeconds

            Kirigami.FormData.label: i18n("Other announcements:")
            from: 2
            to: 15
            textFromValue: (value, locale) => i18np("%1 second", "%1 seconds", value)
            valueFromText: (text, locale) => {
                const parsed = parseInt(text);
                return isFinite(parsed) ? Math.max(from, Math.min(to, parsed)) : from;
            }
        }
    }
}
