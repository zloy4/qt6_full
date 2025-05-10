#include <QGuiApplication>
#include <QtQml/QQmlApplicationEngine>  // Новый корректный путь

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;
    engine.load(QUrl::fromLocalFile("/home/user/weather/main.qml"));

    return app.exec();
}
