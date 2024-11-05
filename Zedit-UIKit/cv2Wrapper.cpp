//
//  cv2Wrapper.cpp
//  Zedit-UIKit
//
//  Created by VR on 05/11/24.
//

//#include "cv2Wrapper.hpp"
//#include <opencv2/opencv.hpp>
//#include <iostream>
//#include <vector>
//#include <string>
//#include <ctime>
//#include <cstdio>
//#include <cstdlib>
//#include <fstream>
//#include <curl/curl.h>
//#include <sstream>
//
//#define THRESHOLD 6.0
//#define MIN_SCENE_DURATION 15
//
//struct SceneRange
//{
//    double start;
//    double end;
//};
//
//void detect_scene_changes(const std::string &video_path, std::std::vector<SceneRange> &scene_ranges)
//{
//    cv::VideoCapture cap(video_path);
//    if (!cap.isOpened())
//    {
//        return;
//    }
//
//    double fps = cap.get(cv::CAP_PROP_FPS);
//    int total_frames = static_cast<int>(cap.get(cv::CAP_PROP_FRAME_COUNT));
//    int min_frames_between_scenes = static_cast<int>(fps * MIN_SCENE_DURATION);
//
//    std::std::vector<double> scene_changes;
//    scene_changes.push_back(0);
//
//    cv::Mat prev_frame;
//    int frame_count = 0;
//    int last_scene_frame = 0;
//
//    while (true)
//    {
//        cv::Mat frame;
//        bool ret = cap.read(frame);
//        if (!ret)
//            break;
//
//        cv::Mat small_frame;
//        cv::resize(frame, small_frame, cv::Size(320, 180));
//        cv::Mat gray;
//        cv::cvtColor(small_frame, gray, cv::COLOR_BGR2GRAY);
//
//        if (!prev_frame.empty() && frame_count - last_scene_frame > min_frames_between_scenes)
//        {
//            cv::Mat diff;
//            cv::absdiff(gray, prev_frame, diff);
//            double mean_diff = cv::mean(diff)[0];
//
//            if (mean_diff > THRESHOLD)
//            {
//                double timestamp = frame_count / fps;
//                scene_changes.push_back(timestamp);
//                last_scene_frame = frame_count;
//            }
//        }
//
//        prev_frame = gray;
//        frame_count++;
//
//        if (frame_count % 100 == 0)
//        {
//            std::cout << "\rProgress: " << (frame_count / static_cast<double>(total_frames)) * 100 << "%" << std::flush;
//        }
//    }
//
//    scene_changes.push_back(frame_count / fps);
//    cap.release();
//
//    for (size_t i = 0; i < scene_changes.size() - 1; ++i)
//    {
//        scene_ranges.push_back({scene_changes[i], scene_changes[i + 1]});
//    }
//}
//
//cv::Mat extract_keyframe(const std::string &video_path, double timestamp)
//{
//    cv::VideoCapture cap(video_path);
//    cap.set(cv::CAP_PROP_POS_MSEC, timestamp * 1000);
//    cv::Mat frame;
//    cap.read(frame);
//    cap.release();
//    return frame;
//}
//
//size_t WriteCallback(void *contents, size_t size, size_t nmemb, void *userp)
//{
//    ((std::string *)userp)->append((char *)contents, size * nmemb);
//    return size * nmemb;
//}
//
//std::string analyze_frame_llava(const cv::Mat &frame)
//{
//    std::string temp_filename = "temp_frame.png";
//    cv::imwrite(temp_filename, frame);
//
//    CURL *curl;
//    CURLcode res;
//    curl_global_init(CURL_GLOBAL_DEFAULT);
//    curl = curl_easy_init();
//
//    std::string readBuffer;
//
//    if (curl)
//    {
//        curl_easy_setopt(curl, CURLOPT_URL, "http://localhost:8000/analyze-image/");
//        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteCallback);
//        curl_easy_setopt(curl, CURLOPT_WRITEDATA, &readBuffer);
//
//        struct curl_httppost *formpost = NULL;
//        struct curl_httppost *lastptr = NULL;
//
//        curl_formadd(&formpost,
//                     &lastptr,
//                     CURLFORM_COPYNAME, "file",
//                     CURLFORM_FILE, temp_filename.c_str(),
//                     CURLFORM_CONTENTTYPE, "image/png",
//                     CURLFORM_END);
//
//        curl_easy_setopt(curl, CURLOPT_HTTPPOST, formpost);
//
//        res = curl_easy_perform(curl);
//
//        if (res != CURLE_OK)
//            fprintf(stderr, "curl_easy_perform() failed: %s\n", curl_easy_strerror(res));
//
//        curl_easy_cleanup(curl);
//        curl_formfree(formpost);
//    }
//
//    curl_global_cleanup();
//
//    std::remove(temp_filename.c_str());
//
//    return readBuffer;
//}
//
//int main()
//{
//    const std::string video_path = "vid1.mp4";
//
//    std::cout << "Detecting scenes..." << std::endl;
//    clock_t start_time = clock();
//
//    std::vector<SceneRange> scene_ranges;
//    detect_scene_changes(video_path, scene_ranges);
//
//    std::cout << "\nFound " << scene_ranges.size() << " scenes" << std::endl;
//    std::cout << "Scene Ranges:" << std::endl;
//    for (size_t i = 0; i < scene_ranges.size(); ++i)
//    {
//        std::cout << "Scene " << i + 1 << ": " << scene_ranges[i].start << " - " << scene_ranges[i].end << std::endl;
//    }
//
//    std::cout << "\nAnalyzing scenes..." << std::endl;
//    for (size_t i = 0; i < scene_ranges.size(); ++i)
//    {
//        double mid_time = (scene_ranges[i].start + scene_ranges[i].end) / 2;
//        cv::Mat frame = extract_keyframe(video_path, mid_time);
//        if (!frame.empty())
//        {
//            std::cout << "\nAnalyzing scene " << i + 1 << "/" << scene_ranges.size() << std::endl;
//            std::cout << analyze_frame_llava(frame);
//        }
//    }
//
//    std::cout << "\nTotal execution time: " << static_cast<double>(clock() - start_time) / (CLOCKS_PER_SEC) << " seconds" << std::endl;
//    return 0;
//}
