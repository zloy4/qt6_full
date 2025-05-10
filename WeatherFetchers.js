var apiKey = "53f2e1b43a53b9ec86018cdf1e816cfa"
var baseUrl = "https://api.openweathermap.org/data/2.5/weather"
var forecastUrl = "https://api.openweathermap.org/data/2.5/forecast"

function convertToFahrenheit(celsius) {
    return Math.round((celsius * 9/5 + 32) * 10) / 10
}

function fetchWeather(city) {
    if (!city) {
        errorMessage.text = qsTr("Введите город")
        errorMessage.visible = true
        return
    }

    console.log("Запрос текущей погоды для города: " + city)
    var xhr = new XMLHttpRequest()
    var url = baseUrl + "?q=" + encodeURIComponent(city) +
              "&appid=" + apiKey + "&units=metric&lang=ru"

    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                console.log("Текущая погода успешно получена")
                var response = JSON.parse(xhr.responseText)
                cityName.text = qsTr("Город: ") + response.name

                var tempC = response.main.temp
                var tempF = convertToFahrenheit(tempC)
                temperature.text = qsTr("Температура: ") +
                    (useCelsius ? tempC + "°C" : tempF + "°F")

                description.text = qsTr("Описание: ") + response.weather[0].description
                humidity.text = qsTr("Влажность: ") + response.main.humidity + "%"
                wind.text = qsTr("Ветер: ") + response.wind.speed + " м/с"
                errorMessage.visible = false
                weatherBlock.opacity = 1.0

                fetchForecast(city)
                fetchHourlyData(city)
            } else {
                console.error("Ошибка API: " + xhr.status + " " + xhr.statusText)
                errorMessage.text = qsTr("Ошибка: проверьте название города")
                errorMessage.visible = true
                weatherBlock.opacity = 0.0
                forecastBlock.opacity = 0.0
                chartBlock.opacity = 0.0
            }
        }
    }

    xhr.open("GET", url)
    xhr.send()
}

function fetchForecast(city) {
    console.log("Запрос прогноза для города: " + city)
    var xhr = new XMLHttpRequest()
    var url = forecastUrl + "?q=" + encodeURIComponent(city) +
              "&appid=" + apiKey + "&units=metric&lang=ru"

    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                console.log("Прогноз успешно получен")
                var response = JSON.parse(xhr.responseText)
                var dailyForecasts = processForecastData(response.list)
                forecastModel.clear()

                for (var i = 0; i < dailyForecasts.length; i++) {
                    console.log("Прогноз день " + i + ": дата=" + dailyForecasts[i].date +
                                ", темп=" + dailyForecasts[i].temp + ", описание=" + dailyForecasts[i].desc)
                    forecastModel.append({
                        date: dailyForecasts[i].date,
                        temp: dailyForecasts[i].temp,
                        tempF: dailyForecasts[i].tempF,
                        desc: dailyForecasts[i].desc
                    })
                }
                forecastBlock.opacity = 1.0
            } else {
                console.error("Ошибка прогноза: " + xhr.status + " " + xhr.statusText)
                errorMessage.text = qsTr("Ошибка при загрузке прогноза")
                errorMessage.visible = true
                forecastBlock.opacity = 0.0
            }
        }
    }

    xhr.open("GET", url)
    xhr.send()
}

function fetchHourlyData(city) {
    console.log("Запрос почасовых данных для города: " + city)
    var xhr = new XMLHttpRequest()
    var url = forecastUrl + "?q=" + encodeURIComponent(city) +
              "&appid=" + apiKey + "&units=metric&lang=ru"

    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                console.log("Почасовые данные успешно получены")
                var response = JSON.parse(xhr.responseText)
                var hourlyData = processHourlyData(response.list)
                console.log("Получено почасовых записей: " + hourlyData.length)
                chartModel.clear()

                for (var i = 0; i < hourlyData.length; i++) {
                    console.log("Добавление в chartModel: время=" + hourlyData[i].time +
                                ", темп=" + hourlyData[i].temp + ", влажность=" + hourlyData[i].humidity +
                                ", ветер=" + hourlyData[i].wind)
                    chartModel.append({
                        time: hourlyData[i].time,
                        temp: hourlyData[i].temp,
                        tempF: hourlyData[i].tempF,
                        humidity: hourlyData[i].humidity,
                        wind: hourlyData[i].wind
                    })
                }
                chartBlock.opacity = 1.0
            } else {
                console.error("Ошибка почасовых данных: " + xhr.status + " " + xhr.statusText)
                errorMessage.text = qsTr("Ошибка при загрузке почасовых данных")
                errorMessage.visible = true
                chartBlock.opacity = 0.0
            }
        }
    }

    xhr.open("GET", url)
    xhr.send()
}

function processForecastData(list) {
    var dailyData = {}
    var currentDate = new Date()
    currentDate.setHours(0, 0, 0, 0)

    for (var i = 0; i < list.length; i++) {
        var item = list[i]
        var itemDate = new Date(item.dt * 1000)
        var dayKey = itemDate.toISOString().split('T')[0]

        if (itemDate.getDate() === currentDate.getDate()) continue

        if (!dailyData[dayKey]) {
            dailyData[dayKey] = {
                temps: [],
                tempsF: [],
                desc: item.weather[0].description
            }
        }
        dailyData[dayKey].temps.push(item.main.temp)
        dailyData[dayKey].tempsF.push(convertToFahrenheit(item.main.temp))
    }

    var result = []
    var keys = Object.keys(dailyData).sort()
    for (var i = 0; i < keys.length && i < 4; i++) {
        var key = keys[i]
        var temps = dailyData[key].temps
        var tempsF = dailyData[key].tempsF
        var avgTemp = temps.reduce((a, b) => a + b, 0) / temps.length
        var avgTempF = tempsF.reduce((a, b) => a + b, 0) / tempsF.length

        result.push({
            date: new Date(key).toLocaleDateString('ru-RU', { weekday: 'long' }),
            temp: Math.round(avgTemp * 10) / 10,
            tempF: Math.round(avgTempF * 10) / 10,
            desc: dailyData[key].desc
        })
    }

    return result
}

function processHourlyData(list) {
    var result = []

    for (var i = 0; i < list.length && result.length < 8; i++) {
        var item = list[i]
        var itemDate = new Date(item.dt * 1000)
        console.log("Почасовая запись " + i + ": время=" + itemDate.toLocaleString('ru-RU') +
                    ", темп=" + item.main.temp + ", влажность=" + item.main.humidity +
                    ", ветер=" + item.wind.speed)

        result.push({
            time: itemDate.toLocaleTimeString('ru-RU', { hour: '2-digit', minute: '2-digit' }),
            temp: Math.round(item.main.temp * 10) / 10,
            tempF: convertToFahrenheit(item.main.temp),
            humidity: item.main.humidity,
            wind: item.wind.speed
        })
    }

    console.log("Обработано почасовых записей: " + result.length)
    return result
}
