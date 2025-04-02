//
//  CVFunctions.cpp
//  Zedit-UIKit
//
//  Created by VR on 02/01/25.
//

#include "CVFuntions.hpp"

#define THRESHOLD 6.0

namespace CVFuncs
{
    ProcessingError detect_scene_changes(const std::string &video_path, std::vector<SceneRange> &scene_ranges, double MIN_SCENE_DURATION)
    {
        ProcessingError error = {false, ""};

        try
        {
            cv::VideoCapture cap;
            if (!cap.open(video_path, cv::CAP_ANY))
            {
                if (!cap.open(video_path, cv::CAP_FFMPEG))
                {
                    if (!cap.open(video_path, cv::CAP_AVFOUNDATION))
                    {
                        error.hasError = true;
                        error.message = "Failed to open video with any backend at: " + video_path;
                        return error;
                    }
                }
            }

            double fps = cap.get(cv::CAP_PROP_FPS);
            int min_frames_between_scenes = static_cast<int>(fps * MIN_SCENE_DURATION);

            std::vector<double> scene_changes;
            scene_changes.push_back(0);

            cv::Mat prev_frame;
            int frame_count = 0;
            int last_scene_frame = 0;

            while (true)
            {
                cv::Mat frame;
                if (!cap.read(frame))
                    break;

                cv::Mat gray;
                cv::cvtColor(frame, gray, cv::COLOR_BGR2GRAY);

                if (!prev_frame.empty() &&
                    frame_count - last_scene_frame > min_frames_between_scenes)
                {
                    cv::Mat diff;
                    cv::absdiff(gray, prev_frame, diff);
                    double mean_diff = cv::mean(diff)[0];

                    if (mean_diff > THRESHOLD)
                    {
                        scene_changes.push_back(frame_count / fps);
                        last_scene_frame = frame_count;
                    }
                }

                prev_frame = gray.clone();
                frame_count++;
            }

            scene_changes.push_back(frame_count / fps);

            for (size_t i = 0; i < scene_changes.size() - 1; ++i)
            {
                scene_ranges.push_back({scene_changes[i], scene_changes[i + 1]});
            }
        }
        catch (const cv::Exception &e)
        {
            error.hasError = true;
            error.message = std::string("OpenCV error: ") + e.what();
        }
        return error;
    }
}
