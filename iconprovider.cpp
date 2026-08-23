#include "iconprovider.h"

#include <QFile>
#include <QPainter>
#include <QSvgRenderer>
#include <QUrl>
#include <QUrlQuery>

IconProvider::IconProvider()
    : QQuickImageProvider(QQuickImageProvider::Image) {}

/* id 是 image://icons/<path>?size=<n>&color=<hex>
 * 从 id 中解析 path 和 query 参数 */
QImage IconProvider::requestImage(const QString& id, QSize* size,
                                  const QSize& requestedSize) {
    /* 解析 URL: id 格式为 "image://icons/<path>" + query 部分 */
    QUrl url(id);
    QString p = url.path();
    QUrlQuery query(url);

    QFile f(p);
    if (!f.open(QIODevice::ReadOnly)) return {};
    QSvgRenderer renderer(f.readAll());
    if (!renderer.isValid()) return {};

    /* 优先 query.size, 否则 requestedSize, 否则默认 24 */
    int req = 24;
    bool ok = false;
    int qsize = query.queryItemValue(QStringLiteral("size")).toInt(&ok);
    if (ok && qsize > 0) req = qsize;
    else if (requestedSize.isValid() && requestedSize.width() > 0)
        req = requestedSize.width();

    QImage img(req, req, QImage::Format_ARGB32_Premultiplied);
    img.fill(Qt::transparent);
    QPainter painter(&img);
    painter.setRenderHint(QPainter::Antialiasing, true);
    renderer.render(&painter);
    painter.end();

    /* 着色: SVG alpha 当 mask, 用 color 整体替换
     * color 为空则保留 SVG 原色 (彩色 logo 等) */
    const QString color = query.queryItemValue(QStringLiteral("color"));
    if (!color.isEmpty()) {
        const QColor c(color);
        if (c.isValid()) {
            QPainter p2(&img);
            p2.setCompositionMode(QPainter::CompositionMode_SourceIn);
            p2.fillRect(img.rect(), c);
        }
    }

    if (size) *size = img.size();
    return img;
}
