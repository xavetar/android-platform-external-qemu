// Copyright (C) 2017 The Android Open Source Project
//
// This software is licensed under the terms of the GNU General Public
// License version 2, as published by the Free Software Foundation, and
// may be copied, distributed, and modified under those terms.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

#include "android/skin/qt/extended-pages/record-screen-page.h"

#include "android/base/files/PathUtils.h"
#include "android/emulation/control/record_screen_agent.h"
#include "android/globals.h"
#include "android/recording/GifConverter.h"
#include "android/skin/qt/error-dialog.h"
#include "android/skin/qt/extended-pages/common.h"
#include "android/skin/qt/extended-pages/record-screen-page-tasks.h"
#include "android/skin/qt/qt-settings.h"
#include "android/skin/qt/stylesheet.h"
#include "android/skin/qt/video-player/VideoPlayerNotifier.h"
#include "android/utils/debug.h"

#include <QDesktopServices>
#include <QFileDialog>
#include <QMovie>
#include <QSettings>
#include <QThread>

using android::base::PathUtils;

// static
const char RecordScreenPage::kTmpMediaName[] = "tmp.webm";
const QAndroidRecordScreenAgent* RecordScreenPage::sRecordScreenAgent = nullptr;

RecordScreenPage::RecordScreenPage(QWidget* parent)
    : QWidget(parent), mUi(new Ui::RecordScreenPage) {
    mUi->setupUi(this);

    // Resize format combobox width to the largest item
    mUi->rec_formatSwitch->setMinimumContentsLength(5);
    int width = mUi->rec_formatSwitch->minimumSizeHint().width();
    mUi->rec_formatSwitch->setMinimumWidth(width);

    // Create widget for video player
    mVideoWidget.reset(new android::videoplayer::VideoPlayerWidget(this));
    mUi->rec_playerOverlayLayout->addWidget(mVideoWidget.get());
    // Need to call show() on the parent widget to notify mVideoWidget to resize
    // to match the size of rec_playerOverlayWidget.
    mUi->rec_playerOverlayWidget->show();

    setRecordUiState(RecordUiState::Ready);

    mTmpFilePath = PathUtils::join(avdInfo_getContentPath(android_avdInfo),
                                   &kTmpMediaName[0]);
    qRegisterMetaType<RecordingStatus>();
    QObject::connect(&mTimer, &QTimer::timeout, this,
                     &RecordScreenPage::updateElapsedTime);
    QObject::connect(this, &RecordScreenPage::recordingStatusChange, this,
                     &RecordScreenPage::slot_recordingStatusChange);
}

RecordScreenPage::~RecordScreenPage() {
    // Remove the tmp video file if one exists
    if (!removeFileIfExists(QString(mTmpFilePath.c_str()))) {
        derror("Unable to clean up temp media file.");
    }
}

bool RecordScreenPage::removeFileIfExists(const QString& file) {
    if (QFile::exists(file)) {
        return QFile::remove(file);
    }
    return true;
}

static void onRecordingStatusChanged(void* opaque, RecordingStatus status) {
    RecordScreenPage* rsInst = (RecordScreenPage*)opaque;
    if (rsInst) {
        rsInst->emitRecordingStatusChange(status);
    }
}

void RecordScreenPage::emitRecordingStatusChange(RecordingStatus status) {
    emit(recordingStatusChange(status));
}

// static
void RecordScreenPage::setRecordScreenAgent(
        const QAndroidRecordScreenAgent* agent) {
    sRecordScreenAgent = agent;
}

void RecordScreenPage::setRecordUiState(RecordUiState newState) {
    mState = newState;

    switch (mState) {
        case RecordUiState::Ready:
            mUi->rec_recordOverlayWidget->show();
            mUi->rec_timeElapsedWidget->hide();
            mUi->rec_playStopButton->hide();
            mUi->rec_formatSwitch->hide();
            mUi->rec_saveButton->hide();
            mUi->rec_timeResLabel->hide();
            mUi->rec_recordButton->setText(QString("START RECORDING"));
            mUi->rec_recordButton->show();
            mVideoWidget->setVisible(false);
            break;
        case RecordUiState::Starting: {
            SettingsTheme theme = getSelectedTheme();
            QMovie* movie = new QMovie(this);
            movie->setFileName(":/" +
                               Ui::stylesheetValues(theme)[Ui::THEME_PATH_VAR] +
                               "/circular_spinner");
            if (movie->isValid()) {
                movie->start();
                mUi->rec_recordDotLabel->setMovie(movie);
            }
            mUi->rec_timeElapsedLabel->setText("Starting the recorder");
            mUi->rec_timeElapsedWidget->show();
            mUi->rec_recordButton->hide();
            break;
        }
        case RecordUiState::Recording:
            mUi->rec_recordDotLabel->setPixmap(QPixmap(QString::fromUtf8(":/light/recordCircle")));
            mUi->rec_recordOverlayWidget->show();
            mUi->rec_timeElapsedLabel->setText("0s Recording...");
            mUi->rec_timeElapsedWidget->show();
            mUi->rec_playStopButton->hide();
            mUi->rec_formatSwitch->hide();
            mUi->rec_saveButton->hide();
            mUi->rec_timeResLabel->hide();
            mUi->rec_recordButton->setText(QString("STOP RECORDING"));
            mUi->rec_recordButton->show();
            mVideoWidget->setVisible(false);

            // Update every second
            mSec = 0;
            // connect(mTimer, SIGNAL(timeout()), this,
            // SLOT(updateElapsedTime()));
            mTimer.start(1000);
            break;
        case RecordUiState::Stopping: {
            mTimer.stop();
            SettingsTheme theme = getSelectedTheme();
            QMovie* movie = new QMovie(this);
            movie->setFileName(":/" + Ui::stylesheetValues(theme)[Ui::THEME_PATH_VAR] +
                               "/circular_spinner");
            if (movie->isValid()) {
                movie->start();
                mUi->rec_recordDotLabel->setMovie(movie);
            }
            mUi->rec_timeElapsedLabel->setText("Finishing encoding");
            mUi->rec_recordButton->hide();
            // Set back to webm format
            mUi->rec_formatSwitch->setCurrentIndex(0);
            break;
        }
        case RecordUiState::Playing:
            mUi->rec_recordOverlayWidget->hide();
            // Change the icon on the play/stop button.
            mUi->rec_playStopButton->show();
            mUi->rec_playStopButton->setIcon(getIconForCurrentTheme("stop"));
            mUi->rec_playStopButton->setProperty("themeIconName", "stop");
            break;
        case RecordUiState::Stopped:
            mUi->rec_recordOverlayWidget->show();
            mUi->rec_timeElapsedWidget->hide();
            mUi->rec_playStopButton->show();
            mUi->rec_formatSwitch->show();
            mUi->rec_saveButton->show();
            // Get the video duration from the video's metadata.
            mSec = mVideoInfo->getDurationSecs();
            mUi->rec_timeResLabel->setText(
                    QString("%1s / %2 x %3")
                            .arg(mSec)
                            .arg(android_hw->hw_lcd_width)
                            .arg(android_hw->hw_lcd_height));
            mUi->rec_timeResLabel->show();
            mUi->rec_recordButton->setText(QString("RECORD AGAIN"));
            mUi->rec_recordButton->show();
            mUi->rec_playStopButton->setEnabled(true);
            mUi->rec_formatSwitch->setEnabled(true);
            mUi->rec_saveButton->setEnabled(true);
            mUi->rec_playStopButton->setIcon(getIconForCurrentTheme("play_arrow"));
            mUi->rec_playStopButton->setProperty("themeIconName", "play_arrow");
            // Display preview frame
            mVideoInfo->show();
            mVideoWidget->setVisible(true);
            break;
        case RecordUiState::Converting: {
            SettingsTheme theme = getSelectedTheme();
            QMovie* movie = new QMovie(this);
            movie->setFileName(":/" + Ui::stylesheetValues(theme)[Ui::THEME_PATH_VAR] +
                               "/circular_spinner");
            if (movie->isValid()) {
                movie->start();
                mUi->rec_recordDotLabel->setMovie(movie);
            }
            mUi->rec_timeElapsedLabel->setText("Converting to gif");
            mUi->rec_timeElapsedWidget->show();
            mUi->rec_recordButton->hide();
            mUi->rec_playStopButton->setEnabled(false);
            mUi->rec_formatSwitch->setEnabled(false);
            mUi->rec_saveButton->setEnabled(false);
            break;
        }
        default:;
    }
}

void RecordScreenPage::updateElapsedTime() {
    QString qs = QString("%1s Recording...").arg(++mSec);
    mUi->rec_timeElapsedLabel->setText(qs);
    mTimer.start(1000);
}

void RecordScreenPage::on_rec_playStopButton_clicked() {
    if (mState == RecordUiState::Stopped) {
        auto videoPlayerNotifier =
                std::unique_ptr<android::videoplayer::VideoPlayerNotifier>(
                        new android::videoplayer::VideoPlayerNotifier());
        connect(videoPlayerNotifier.get(), SIGNAL(updateWidget()), this,
                SLOT(updateVideoView()));
        connect(videoPlayerNotifier.get(), SIGNAL(videoFinished()), this,
                SLOT(videoPlayingFinished()));
        mVideoPlayer = android::videoplayer::VideoPlayer::create(
                mTmpFilePath, mVideoWidget.get(),
                std::move(videoPlayerNotifier));

        mVideoPlayer->scheduleRefresh(20);
        mVideoPlayer->start();
        setRecordUiState(RecordUiState::Playing);
    } else if (mState == RecordUiState::Playing) {
        mVideoPlayer->stop();
        mUi->rec_playStopButton->setIcon(getIconForCurrentTheme("play_arrow"));
        mUi->rec_playStopButton->setProperty("themeIconName", "play_arrow");
        // stop call will cause videoPlayingFinished() method to be called
        // where we update the button state
    }
}

void RecordScreenPage::on_rec_recordButton_clicked() {
    RecordUiState newState = RecordUiState::Ready;

    if (!sRecordScreenAgent) {
        // agent not ready yet
        return;
    }

    switch (mState) {
        case RecordUiState::Ready:
        case RecordUiState::Stopped: {
            // startRecording() will determine which codec to use based on the
            // file extension.
            RecordingInfo info = {};
            info.fileName = mTmpFilePath.c_str();
            info.cb = &onRecordingStatusChanged;
            info.opaque = this;
            if (!sRecordScreenAgent->startRecordingAsync(&info)) {
                QString errStr =
                        tr("Failed to start the recording. If you are "
                           "recording from the command-line, you must stop "
                           "that recording to record from here.");
                showErrorDialog(errStr, tr("Start Recording"));
            }
            break;
        }
        case RecordUiState::Recording: {
            if (!sRecordScreenAgent->stopRecordingAsync()) {
                QString errStr =
                        tr("Failed to stop the recording. Recording was either "
                           "stopped from the command-line or the time limit "
                           "was reached.\n");
                setRecordUiState(RecordUiState::Ready);
            }
            return;
        }
        default:;
    }

    setRecordUiState(newState);
}

void RecordScreenPage::on_rec_saveButton_clicked() {
    QSettings settings;

    // Stop the video player if it's running
    if (mVideoPlayer && mVideoPlayer->isRunning()) {
        mVideoPlayer->stop();
    }

    QString ext = mUi->rec_formatSwitch->currentText().toLower();
    QString savePath = QDir::toNativeSeparators(getRecordingSaveDirectory());
    QString recordingName = QFileDialog::getSaveFileName(
            this, tr("Save Recording"),
            savePath + QString("/untitled.%1").arg(ext),
            tr("Multimedia (*.%1)").arg(ext));

    if (recordingName.isEmpty())
        return;  // Operation was canceled

    QFileInfo fileInfo(recordingName);
    QString dirName = fileInfo.absolutePath();

    dirName = QDir::toNativeSeparators(dirName);

    if (!directoryIsWritable(dirName)) {
        QString errStr = tr("The path is not writable:<br>") + dirName;
        showErrorDialog(errStr, tr("Save Recording"));
        return;
    }

    settings.setValue(Ui::Settings::SCREENREC_SAVE_PATH, dirName);

    // Copy the media file to the save location
    if (ext == "gif") {
        auto thread = new QThread();
        auto task = new ConvertingTask(mTmpFilePath, recordingName.toStdString());
        task->moveToThread(thread);
        connect(thread, SIGNAL(started()), task, SLOT(run()));
        connect(task, SIGNAL(started()), this, SLOT(convertingStarted()));
        connect(task, SIGNAL(finished(bool)), this, SLOT(convertingFinished(bool)));
        connect(task, SIGNAL(finished(bool)), thread, SLOT(quit()));
        connect(thread, SIGNAL(finished()), task, SLOT(deleteLater()));
        connect(thread, SIGNAL(finished()), thread, SLOT(deleteLater()));
        thread->start();
    } else {
        QString errStr;

        if (removeFileIfExists(recordingName)) {
            if (!QFile::copy(QString(mTmpFilePath.c_str()), recordingName)) {
                errStr = tr("Unknown error while saving<br>") + recordingName;
                showErrorDialog(errStr, tr("Save Recording"));
            }
        } else {
            errStr = tr("Unable to remove existing file before copying new "
                        "file<br>") +
                     recordingName;
            showErrorDialog(errStr, tr("Save Recording"));
        }
    }
}

void RecordScreenPage::updateTheme() {
    if (mState != RecordUiState::Stopping &&
        mState != RecordUiState::Converting) {
        return;
    }

    SettingsTheme theme = getSelectedTheme();
    QMovie* movie = new QMovie(this);
    movie->setFileName(":/" + Ui::stylesheetValues(theme)[Ui::THEME_PATH_VAR] +
                       "/circular_spinner");
    if (movie->isValid()) {
        movie->start();
        mUi->rec_recordDotLabel->setMovie(movie);
    }
}

void RecordScreenPage::slot_recordingStatusChange(RecordingStatus status) {
    switch (status) {
        case RECORD_START_INITIATED:
            setRecordUiState(RecordUiState::Starting);
            break;
        case RECORD_STARTED:
            setRecordUiState(RecordUiState::Recording);
            break;
        case RECORD_START_FAILED: {
            QString errStr =
                    tr("An error occurred while trying to start the recorder.");
            showErrorDialog(errStr, tr("Start Recording"));
            setRecordUiState(RecordUiState::Ready);
            break;
        }
        case RECORD_STOP_INITIATED:
            setRecordUiState(RecordUiState::Stopping);
            break;
        case RECORD_STOPPED:
            mVideoPlayer.reset();
            // Setup the preview frame. Needs to be initialized before
            // setRecordUiState() or the preview frame will not be shown.
            mVideoInfo.reset(new android::videoplayer::VideoInfo(
                    mVideoWidget.get(), mTmpFilePath));
            connect(mVideoInfo.get(), SIGNAL(updateWidget()), this,
                    SLOT(updateVideoView()));
            setRecordUiState(RecordUiState::Stopped);
            break;
        case RECORD_STOP_FAILED: {
            QString errStr = tr("An error occurred while recording.");
            showErrorDialog(errStr, tr("Save Recording"));
            setRecordUiState(RecordUiState::Ready);
            break;
        }
        default:
            break;
    }
}

void RecordScreenPage::convertingStarted() {
    setRecordUiState(RecordUiState::Converting);
}

void RecordScreenPage::convertingFinished(bool success) {
    if (!success) {
        QString errStr = tr("An error occurred while converting to gif.");
        showErrorDialog(errStr, tr("Save Recording"));
    }

    setRecordUiState(RecordUiState::Stopped);
}

StopRecordingTask::StopRecordingTask(const QAndroidRecordScreenAgent* agent)
    : mRecordScreenAgent(agent) {}

void StopRecordingTask::run() {
    emit started();
    if (!mRecordScreenAgent) {
        emit(finished(false));
    }
    // The encoder may take some time to finish encoding whatever remaining frames it still has.
    mRecordScreenAgent->stopRecording();
    emit(finished(true));
}

ConvertingTask::ConvertingTask(const std::string& startFilename,
                               const std::string& endFilename)
    : mStartFilename(startFilename),
      mEndFilename(endFilename) {}

void ConvertingTask::run() {
    emit started();
    bool rc = android::recording::GifConverter::toAnimatedGif(
            mStartFilename, mEndFilename, 64 * 1024);
    emit(finished(rc));
}

void RecordScreenPage::updateVideoView() {
    mVideoWidget->repaint();
}

void RecordScreenPage::videoPlayingFinished() {
    setRecordUiState(RecordUiState::Stopped);
}