//
//  HalfModalPresentationController.swift
//  RestoControl
//
//  Created by Ruben Freddy Quea Jacho on 12/12/23.
//

import Foundation

import UIKit

class HalfModalPresentationController: UIPresentationController {
    
    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = containerView else { return .zero }
        return CGRect(x: 0, y: containerView.bounds.height / 2, width: containerView.bounds.width, height: containerView.bounds.height / 2)
    }
    
    override func presentationTransitionWillBegin() {
        guard let containerView = containerView, let presentedView = presentedView else { return }
        
        // Añade un fondo oscuro detrás del modal
        let dimmingView = UIView(frame: containerView.bounds)
        dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        dimmingView.tag = 999
        dimmingView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dimmingViewTapped)))
        containerView.insertSubview(dimmingView, at: 0)
        
        // Establece la posición inicial del modal
        presentedView.frame = frameOfPresentedViewInContainerView
    }
    
    override func presentationTransitionDidEnd(_ completed: Bool) {
        // Elimina el fondo oscuro si la presentación no se completó
        if !completed {
            containerView?.viewWithTag(999)?.removeFromSuperview()
        }
    }
    
    override func dismissalTransitionWillBegin() {
        // Elimina el fondo oscuro durante la transición de cierre
        containerView?.viewWithTag(999)?.removeFromSuperview()
    }
    
    override func containerViewWillLayoutSubviews() {
        presentedView?.frame = frameOfPresentedViewInContainerView
    }
    
    @objc func dimmingViewTapped() {
        presentingViewController.dismiss(animated: true, completion: nil)
    }
}

