#pragma once

#include <QAbstractListModel>
#include <QDateTime>

class QFileSystemWatcher;

struct PagesModelItem {
    QString path;
    QDateTime lastModified;
    QString title;
    QString category;
};

class PagesModel : public QAbstractListModel
{
    Q_OBJECT
public:
    explicit PagesModel(const QString &path, QObject *parent = nullptr);

    enum Roles {
        TitleRole = Qt::UserRole + 1,
        CategoryRole
    };

    QHash<int, QByteArray> roleNames() const override;
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;

    void reload();
private:
    QList<PagesModelItem> load() const;

    static void readMetadata(PagesModelItem &item);
    static void readMetadata(QList<PagesModelItem> &items);

    QString m_path;
    QList<PagesModelItem> m_items;
    QFileSystemWatcher* fsWatcher;
};
