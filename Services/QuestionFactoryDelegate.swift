//
//  QuestionFactoryDelegate.swift
//  MovieQuiz
//
//  Created by Тимур Мурадов on 02.04.2023.
//

import Foundation


protocol QuestionFactoryDelegate {
    func didReceiveNextQuestion(question: QuizQuestion?)
    func didLoadDataFromServer()
    func didFailToLoadData(with error: Error)
    func didFailedToUploadImage(for quizQuestionIndex: Int)
}

