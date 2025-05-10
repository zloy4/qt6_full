import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtCore
import "./WeatherFetchers.js" as WeatherFetcher
ApplicationWindow {
    visible: true
    width: 600
    height: 700
    title: qsTr("Погодный информатор")

    Settings {
        id: appSettings
        property string lastCity: ""
        property string tempUnit: "celsius"
    }

    property bool useCelsius: appSettings.tempUnit === "celsius"

    Rectangle {
        anchors.fill: parent
        color: "#f0f0f0"

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 10
            width: parent.width * 0.9

            // Поле ввода города
            TextField {
                id: cityInput
                placeholderText: qsTr("Введите город")
                Layout.preferredWidth: 300
                font.pointSize: 14
                background: Rectangle {
                    color: "#ffffff"
                    radius: 5
                    border.color: "#cccccc"
                }
            }

            // Выбор единиц измерения
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: qsTr("Единицы измерения:")
                    font.pointSize: 12
                    color: "#333"
                }

                Button {
                    text: qsTr("°C")
                    font.pointSize: 12
                    highlighted: useCelsius
                    onClicked: {
                        appSettings.tempUnit = "celsius"
                        if (cityInput.text) {
                            WeatherFetcher.fetchWeather(cityInput.text)
                        }
                    }
                    background: Rectangle {
                        color: useCelsius ? "#4caf50" : "#e0e0e0"
                        radius: 5
                    }
                }

                Button {
                    text: qsTr("°F")
                    font.pointSize: 12
                    highlighted: !useCelsius
                    onClicked: {
                        appSettings.tempUnit = "fahrenheit"
                        if (cityInput.text) {
                            WeatherFetcher.fetchWeather(cityInput.text)
                        }
                    }
                    background: Rectangle {
                        color: !useCelsius ? "#4caf50" : "#e0e0e0"
                        radius: 5
                    }
                }
            }

            // Кнопка обновления погоды
            Button {
                text: qsTr("Обновить погоду")
                font.pointSize: 14
                Layout.preferredWidth: 300
                onClicked: {
                    WeatherFetcher.fetchWeather(cityInput.text)
                    appSettings.lastCity = cityInput.text
                }
                background: Rectangle {
                    color: "#4caf50"
                    radius: 5
                }
            }

            // Текущая погода и график рядом
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                // Блок текущей погоды
                ColumnLayout {
                    id: weatherBlock
                    spacing: 8
                    opacity: 0.0
                    Layout.preferredWidth: parent.width * 0.45

                    Behavior on opacity {
                        NumberAnimation { duration: 500 }
                    }

                    Text {
                        id: cityName
                        text: qsTr("Город: -")
                        font.pointSize: 16
                        font.bold: true
                        color: "#333"
                    }

                    Text {
                        id: temperature
                        text: qsTr("Температура: -")
                        font.pointSize: 16
                        color: "#ff5722"
                        font.bold: true
                        Behavior on text {
                            NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
                        }
                    }

                    Text {
                        id: description
                        text: qsTr("Описание: -")
                        font.pointSize: 12
                        color: "#757575"
                    }

                    Text {
                        id: humidity
                        text: qsTr("Влажность: -")
                        font.pointSize: 12
                        color: "#757575"
                    }

                    Text {
                        id: wind
                        text: qsTr("Ветер: -")
                        font.pointSize: 12
                        color: "#757575"
                    }
                }

                // Блок графика
                ColumnLayout {
                    id: chartBlock
                    spacing: 8
                    opacity: 0.0
                    Layout.preferredWidth: parent.width * 0.45

                    Behavior on opacity {
                        NumberAnimation { duration: 500 }
                    }

                    Text {
                        text: qsTr("Почасовой график")
                        font.pointSize: 14
                        font.bold: true
                        color: "#333"
                        Layout.alignment: Qt.AlignHCenter
                    }

                    ListModel {
                        id: chartModel
                    }

                    // Легенда
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 8

                        Row {
                            spacing: 4
                            Rectangle {
                                width: 8
                                height: 8
                                color: "#ff5722"
                            }
                            Text {
                                text: qsTr("Темп.")
                                font.pointSize: 9
                                color: "#333"
                            }
                        }

                        Row {
                            spacing: 4
                            Rectangle {
                                width: 8
                                height: 8
                                color: "#2196f3"
                            }
                            Text {
                                text: qsTr("Влажн.")
                                font.pointSize: 9
                                color: "#333"
                            }
                        }

                        Row {
                            spacing: 4
                            Rectangle {
                                width: 8
                                height: 8
                                color: "#4caf50"
                            }
                            Text {
                                text: qsTr("Ветер")
                                font.pointSize: 9
                                color: "#333"
                            }
                        }
                    }

                    // График на Canvas
                    Canvas {
                        id: chartCanvas
                        Layout.preferredWidth: 160
                        Layout.preferredHeight: 160

                        Component.onCompleted: {
                            console.log("Canvas для графика создан")
                        }

                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)
                            ctx.fillStyle = "#ffffff"
                            ctx.fillRect(0, 0, width, height)

                            console.log("Рисуем график, элементов в chartModel: " + chartModel.count)
                            if (chartModel.count === 0) return

                            // Параметры графика
                            var padding = 30
                            var graphWidth = width - 2 * padding
                            var graphHeight = height - 2 * padding
                            var xStep = chartModel.count > 1 ? graphWidth / (chartModel.count - 1) : graphWidth

                            // Диапазоны значений
                            var tempMin = 999
                            var tempMax = -999
                            var humidityMax = 0
                            var windMax = 0

                            for (var i = 0; i < chartModel.count; i++) {
                                var item = chartModel.get(i)
                                var temp = useCelsius ? item.temp : item.tempF
                                console.log("Элемент " + i + ": время=" + item.time + ", темп=" + temp +
                                            ", влажность=" + item.humidity + ", ветер=" + item.wind)
                                tempMin = Math.min(tempMin, temp)
                                tempMax = Math.max(tempMax, temp)
                                humidityMax = Math.max(humidityMax, item.humidity)
                                windMax = Math.max(windMax, item.wind)
                            }

                            if (tempMin === tempMax) {
                                tempMin -= 5
                                tempMax += 5
                            }
                            tempMin = Math.floor(tempMin)
                            tempMax = Math.ceil(tempMax)
                            humidityMax = Math.ceil(humidityMax / 10) * 10 || 100
                            windMax = Math.ceil(windMax / 5) * 5 || 20

                            console.log("Диапазоны: темп=[" + tempMin + "," + tempMax +
                                        "], влажность=0-" + humidityMax + ", ветер=0-" + windMax)

                            // Отрисовка осей
                            ctx.strokeStyle = "#333"
                            ctx.lineWidth = 1
                            ctx.beginPath()
                            ctx.moveTo(padding, padding)
                            ctx.lineTo(padding, height - padding)
                            ctx.lineTo(width - padding, height - padding)
                            ctx.stroke()

                            // Метки оси X (время)
                            ctx.fillStyle = "#333"
                            ctx.font = "8px Arial"
                            ctx.textAlign = "center"
                            var maxLabels = 4
                            var labelStep = Math.ceil(chartModel.count / maxLabels)
                            for (i = 0; i < chartModel.count; i += labelStep) {
                                var x = padding + i * xStep
                                ctx.fillText(chartModel.get(i).time, x, height - padding + 12)
                            }

                            // Метки оси Y (температура, слева)
                            var tempRange = tempMax - tempMin
                            var tempStep = tempRange / 4
                            ctx.textAlign = "right"
                            for (i = 0; i <= 4; i++) {
                                var y = height - padding - (i * graphHeight / 4)
                                var value = tempMin + i * tempStep
                                ctx.fillText(Math.round(value), padding - 5, y + 3)
                            }

                            // Метки оси Y (влажность, справа)
                            ctx.textAlign = "left"
                            for (i = 0; i <= 4; i++) {
                                var y = height - padding - (i * graphHeight / 4)
                                var value = (i * humidityMax / 4)
                                ctx.fillText(Math.round(value), width - padding + 5, y + 3)
                            }

                            // Отрисовка линий
                            // Температура
                            ctx.strokeStyle = "#ff5722"
                            ctx.lineWidth = 2
                            ctx.beginPath()
                            for (i = 0; i < chartModel.count; i++) {
                                var item = chartModel.get(i)
                                var temp = useCelsius ? item.temp : item.tempF
                                var x = padding + i * xStep
                                var y = height - padding - ((temp - tempMin) / tempRange) * graphHeight
                                if (i === 0) ctx.moveTo(x, y)
                                else ctx.lineTo(x, y)
                            }
                            ctx.stroke()

                            // Влажность
                            ctx.strokeStyle = "#2196f3"
                            ctx.beginPath()
                            for (i = 0; i < chartModel.count; i++) {
                                item = chartModel.get(i)
                                x = padding + i * xStep
                                y = height - padding - (item.humidity / humidityMax) * graphHeight
                                if (i === 0) ctx.moveTo(x, y)
                                else ctx.lineTo(x, y)
                            }
                            ctx.stroke()

                            // Ветер
                            ctx.strokeStyle = "#4caf50"
                            ctx.beginPath()
                            for (i = 0; i < chartModel.count; i++) {
                                item = chartModel.get(i)
                                x = padding + i * xStep
                                y = height - padding - (item.wind / windMax) * graphHeight
                                if (i === 0) ctx.moveTo(x, y)
                                else ctx.lineTo(x, y)
                            }
                            ctx.stroke()
                        }

                        Connections {
                            target: chartModel
                            function onRowsInserted() { chartCanvas.requestPaint() }
                            function onDataChanged() { chartCanvas.requestPaint() }
                            function onRowsRemoved() { chartCanvas.requestPaint() }
                        }

                        Connections {
                            target: chartCanvas
                            function onUseCelsiusChanged() { chartCanvas.requestPaint() }
                        }
                    }
                }
            }

            ColumnLayout {
                id: forecastBlock
                spacing: 8
                opacity: 0.0
                Layout.fillWidth: true

                Behavior on opacity {
                    NumberAnimation { duration: 500 }
                }

                Text {
                    text: qsTr("Прогноз на 4 дня")
                    font.pointSize: 14
                    font.bold: true
                    color: "#333"
                    Layout.alignment: Qt.AlignHCenter
                }

                ListModel {
                    id: forecastModel
                }

                ListView {
                    id: forecastView
                    Layout.fillWidth: true
                    Layout.preferredHeight: contentHeight
                    model: forecastModel
                    spacing: 5
                    clip: true

                    delegate: Rectangle {
                        width: forecastView.width
                        height: 50
                        color: "#ffffff"
                        radius: 5
                        border.color: "#cccccc"

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8

                            Text {
                                text: model.date
                                font.pointSize: 10
                                color: "#333"
                                Layout.preferredWidth: parent.width * 0.4
                                elide: Text.ElideRight
                            }

                            Text {
                                text: useCelsius ? model.temp + "°C" : model.tempF + "°F"
                                font.pointSize: 10
                                color: "#ff5722"
                                font.bold: true
                                Layout.preferredWidth: parent.width * 0.2
                                horizontalAlignment: Text.AlignRight
                            }

                            Text {
                                text: model.desc
                                font.pointSize: 10
                                color: "#757575"
                                Layout.preferredWidth: parent.width * 0.4
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }

            Text {
                id: errorMessage
                color: "red"
                font.pointSize: 10
                wrapMode: Text.Wrap
                visible: false
                width: parent.width * 0.8
                horizontalAlignment: Text.AlignHCenter
            }
        }

        Component.onCompleted: {
            console.log("ApplicationWindow создан")
            if (appSettings.lastCity !== "") {
                cityInput.text = appSettings.lastCity
                WeatherFetcher.fetchWeather(appSettings.lastCity)
            }
        }
    }
}
