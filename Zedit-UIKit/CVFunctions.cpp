//
//  CVFunctions.cpp
//  Zedit-UIKit
//
//  Created by VR on 16/11/24.
//

#include "CVFunctions.hpp"

#define THRESHOLD 6.0
#define MIN_SCENE_DURATION 15

namespace CVFuncs
{
    std::string getVersion()
    {
        return CV_VERSION;
    }

    void detect_scene_changes(const std::string &video_path, std::vector<SceneRange> &scene_ranges)
    {
        cv::VideoCapture cap(video_path);
        if (!cap.isOpened())
        {
            return;
        }

        double fps = cap.get(cv::CAP_PROP_FPS);
        int total_frames = static_cast<int>(cap.get(cv::CAP_PROP_FRAME_COUNT));
        int min_frames_between_scenes = static_cast<int>(fps * MIN_SCENE_DURATION);

        std::vector<double> scene_changes;
        scene_changes.push_back(0);

        cv::Mat prev_frame;
        int frame_count = 0;
        int last_scene_frame = 0;

        while (true)
        {
            cv::Mat frame;
            bool ret = cap.read(frame);
            if (!ret)
                break;

            cv::Mat small_frame;
            cv::resize(frame, small_frame, cv::Size(320, 180));
            cv::Mat gray;
            cv::cvtColor(small_frame, gray, cv::COLOR_BGR2GRAY);

            if (!prev_frame.empty() && frame_count - last_scene_frame > min_frames_between_scenes)
            {
                cv::Mat diff;
                cv::absdiff(gray, prev_frame, diff);
                double mean_diff = cv::mean(diff)[0];

                if (mean_diff > THRESHOLD)
                {
                    double timestamp = frame_count / fps;
                    scene_changes.push_back(timestamp);
                    last_scene_frame = frame_count;
                }
            }

            prev_frame = gray;
            frame_count++;
        }

        scene_changes.push_back(frame_count / fps);
        cap.release();

        for (size_t i = 0; i < scene_changes.size() - 1; ++i)
        {
            scene_ranges.push_back({scene_changes[i], scene_changes[i + 1]});
        }
    }
}
