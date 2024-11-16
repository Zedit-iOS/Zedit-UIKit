//
//  CVFunctions.hpp
//  Zedit-UIKit
//
//  Created by VR on 16/11/24.
//

#ifndef CVFunctions_hpp
#define CVFunctions_hpp

#pragma once
#include <opencv2/opencv.hpp>
#include <vector>
#include <string>

namespace CVFuncs
{
    struct SceneRange
    {
        double start;
        double end;
    };

    std::string getVersion();
    void detect_scene_changes(const std::string &video_path, std::vector<SceneRange> &scene_ranges);
}
#endif
