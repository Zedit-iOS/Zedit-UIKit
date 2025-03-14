//
//  CVFuntions.hpp
//  Zedit-UIKit
//
//  Created by VR on 02/01/25.
//

#ifndef CVFunctions_hpp
#define CVFunctions_hpp

#pragma once
#include <opencv2/opencv.hpp>
#include <vector>
#include <string>

namespace CVFuncs
{
    struct ProcessingError
    {
        bool hasError;
        std::string message;
    };

    struct SceneRange
    {
        double start;
        double end;
    };

    ProcessingError detect_scene_changes(const std::string &video_path, std::vector<SceneRange> &scene_ranges, double max_duration);
}
#endif
