//
//  DataPageViewController.swift
//  VoiceOnly
//
//  Created by Wangchou Lu on H30/05/26.
//  Copyright © 平成30年 Lu, WangChou. All rights reserved.
//
// from https://www.youtube.com/watch?v=9BKwrOoIOcA

import UIKit

class InfiniteChallengeSwipablePage: UIPageViewController {
    static let storyboardId = "InfiniteChallengeSwipablePage"
    var pages = [UIViewController]()

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        for v in view.subviews where v is UIScrollView {
            v.frame = view.bounds
            break
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        func addPage(_ storyboardId: String) {
            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: storyboardId)
            pages.append(vc)
        }
        addPage("SettingPage")
        addLevelPages()
        setViewControllers([pages[1]], direction: .forward, animated: true, completion: nil)

        dataSource = self

        // https://stackoverflow.com/questions/43416456/using-uislider-inside-uipageviewcontroller
        for view in self.view.subviews where view is UIScrollView {
            (view as? UIScrollView)?.delaysContentTouches = false
        }
    }

    func addLevelPages() {
        let vcs: [InfiniteChallengePage] = (0...5).map { _ in
            return UIStoryboard(name: "Main", bundle: nil)
                .instantiateViewController(withIdentifier: "InfiniteChallengePage") as! InfiniteChallengePage
        }
        let pageNames = ["", "入門", "初級", "中級", "上級", "超難問", ""]
        let levels: [Level] = [.lv0, .lv1, .lv2, .lv3, .lv4]

        for i in 0...4 {
            vcs[i].topBarLeftText = pageNames[i]
            vcs[i].topBarTitle = pageNames[i+1]
            vcs[i].topBarRightText = pageNames[i+2]
            vcs[i].level = levels[i]
            pages.append(vcs[i])
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension InfiniteChallengeSwipablePage: UIPageViewControllerDataSource {

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if let index = pages.index(of: viewController),
            index + 1 < pages.count {
            return pages[index + 1]
        }
        return nil
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if let index = pages.index(of: viewController),
            index - 1 >= 0 {
            return pages[index - 1]
        }
        return nil
    }
}
