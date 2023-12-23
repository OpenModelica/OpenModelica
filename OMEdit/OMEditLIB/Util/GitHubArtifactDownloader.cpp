/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */
/*
 * @author Adrian.Pop@liu.se
 */

#include "GitHubArtifactDownloader.h"
#include <QVBoxLayout>
#include <QLabel>
#include <QLineEdit>
#include <QPushButton>
#include <QMessageBox>
#include "NetworkAccessManager.h"
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>

GitHubArtifactDownloader::GitHubArtifactDownloader(QWidget *parent) : QWidget(parent) {
    QVBoxLayout *layout = new QVBoxLayout(this);

    ownerLabel = new QLabel("GitHub Owner:", this);
    ownerInput = new QLineEdit(this);
    layout->addWidget(ownerLabel);
    layout->addWidget(ownerInput);

    repoLabel = new QLabel("GitHub Repository:", this);
    repoInput = new QLineEdit(this);
    layout->addWidget(repoLabel);
    layout->addWidget(repoInput);

    workflowLabel = new QLabel("Workflow ID:", this);
    workflowInput = new QLineEdit(this);
    layout->addWidget(workflowLabel);
    layout->addWidget(workflowInput);

    artifactLabel = new QLabel("Artifact Name:", this);
    artifactInput = new QLineEdit(this);
    layout->addWidget(artifactLabel);
    layout->addWidget(artifactInput);

    tokenLabel = new QLabel("GitHub Token:", this);
    tokenInput = new QLineEdit(this);
    layout->addWidget(tokenLabel);
    layout->addWidget(tokenInput);

    downloadButton = new QPushButton("Download Artifact", this);
    layout->addWidget(downloadButton);

    connect(downloadButton, &QPushButton::clicked, this, &GitHubArtifactDownloader::downloadArtifact);
}

void GitHubArtifactDownloader::downloadArtifact() {
    QString owner = ownerInput->text();
    QString repo = repoInput->text();
    QString workflowId = workflowInput->text();
    QString artifactName = artifactInput->text();
    QString token = tokenInput->text();

    NetworkAccessManager *manager = new NetworkAccessManager(this);

    QNetworkRequest request;
    request.setUrl(QUrl(QString("https://api.github.com/repos/%1/%2/actions/workflows/%3/runs").arg(owner, repo, workflowId)));
    request.setRawHeader("Authorization", QString("token %1").arg(token).toUtf8());
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    QNetworkReply *reply = manager->get(request);
    connect(reply, &QNetworkReply::finished, [=]() {
        if (reply->error() == QNetworkReply::NoError) {
            QByteArray responseData = reply->readAll();
            QJsonDocument jsonDoc = QJsonDocument::fromJson(responseData);
            QJsonObject jsonObject = jsonDoc.object();
            QJsonArray workflowRuns = jsonObject["workflow_runs"].toArray();
            int latestRunId = workflowRuns.at(0).toObject()["id"].toInt();

            QNetworkRequest artifactsRequest;
            artifactsRequest.setUrl(QUrl(QString("https://api.github.com/repos/%1/%2/actions/runs/%3/artifacts").arg(owner, repo, QString::number(latestRunId))));
            artifactsRequest.setRawHeader("Authorization", QString("token %1").arg(token).toUtf8());
            artifactsRequest.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

            QNetworkReply *artifactsReply = manager->get(artifactsRequest);
            connect(artifactsReply, &QNetworkReply::finished, [=]() {
                if (artifactsReply->error() == QNetworkReply::NoError) {
                    QByteArray artifactsData = artifactsReply->readAll();
                    QJsonDocument artifactsDoc = QJsonDocument::fromJson(artifactsData);
                    QJsonObject artifactsObject = artifactsDoc.object();
                    QJsonArray artifacts = artifactsObject["artifacts"].toArray();

                    QString downloadUrl;
                    for (const auto &artifact : artifacts) {
                        if (artifact.toObject()["name"].toString() == artifactName) {
                            downloadUrl = artifact.toObject()["archive_download_url"].toString();
                            break;
                        }
                    }

                    if (!downloadUrl.isEmpty()) {
                        QNetworkRequest downloadRequest;
                        downloadRequest.setUrl(QUrl(downloadUrl));
                        downloadRequest.setRawHeader("Authorization", QString("token %1").arg(token).toUtf8());

                        QNetworkReply *downloadReply = manager->get(downloadRequest);
                        connect(downloadReply, &QNetworkReply::finished, [=]() {
                            if (downloadReply->error() == QNetworkReply::NoError) {
                                QByteArray downloadedData = downloadReply->readAll();
                                QFile file(artifactName + ".zip");
                                if (file.open(QIODevice::WriteOnly)) {
                                    file.write(downloadedData);
                                    file.close();
                                    QMessageBox::information(this, "Success", QString("Artifact '%1' downloaded successfully!").arg(artifactName));
                                } else {
                                    QMessageBox::critical(this, "Error", "Unable to save downloaded artifact!");
                                }
                            } else {
                                QMessageBox::critical(this, "Error", "Download failed!");
                            }
                            downloadReply->deleteLater();
                        });
                    } else {
                        QMessageBox::warning(this, "Warning", QString("Artifact '%1' not found!").arg(artifactName));
                    }
                } else {
                    QMessageBox::critical(this, "Error", "Failed to fetch artifacts!");
                }
                artifactsReply->deleteLater();
            });
        } else {
            QMessageBox::critical(this, "Error", "Failed to fetch workflow runs!");
        }
        reply->deleteLater();
    });
}


