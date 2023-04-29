//
//  QuestionFactory.swift
//  MovieQuiz
//
//  Created by Тимур Мурадов on 25.03.2023.
//
import UIKit
import Foundation

final class QuestionFactory: QuestionFactoryProtocol {
    
    private let moviesLoader: MoviesLoading
    private var delegate: QuestionFactoryDelegate?
    
    private var movies: [MostPopularMovie] = []
    
    func loadData() {
           moviesLoader.loadMovies { [weak self] result in
               DispatchQueue.main.async {
                   guard let self = self else { return }
                   switch result {
                   case .success(let mostPopularMovies):
                       self.movies = mostPopularMovies.items
                       self.delegate?.didLoadDataFromServer()
                   case .failure(let error):
                       self.delegate?.didFailToLoadData(with: error)
                   }
               }
           }
    }
    
    init(moviesLoader: MoviesLoading, delegate: QuestionFactoryDelegate) {
        self.delegate = delegate
        self.moviesLoader = moviesLoader
    }
    
//    private let questions: [QuizQuestion] = [
//        QuizQuestion(
//            image: "The Godfather",
//            text: "Рейтинг этого фильма больше чем 6?",
//            correctAnswer: true),
//        QuizQuestion(
//            image: "The Dark Knight",
//            text: "Рейтинг этого фильма больше чем 6?",
//            correctAnswer: true),
//        QuizQuestion(
//            image: "Kill Bill",
//            text: "Рейтинг этого фильма больше чем 6?",
//            correctAnswer: true),
//        QuizQuestion(
//            image: "The Avengers",
//            text: "Рейтинг этого фильма больше чем 6?",
//            correctAnswer: true),
//        QuizQuestion(
//            image: "Deadpool",
//            text: "Рейтинг этого фильма больше чем 6?",
//            correctAnswer: true),
//        QuizQuestion(
//            image: "The Green Knight",
//            text: "Рейтинг этого фильма больше чем 6?",
//            correctAnswer: true),
//        QuizQuestion(
//            image: "Old",
//            text: "Рейтинг этого фильма больше чем 6?",
//            correctAnswer: false),
//        QuizQuestion(
//            image: "The Ice Age Adventures of Buck Wild",
//            text: "Рейтинг этого фильма больше чем 6?",
//            correctAnswer: false),
//        QuizQuestion(
//            image: "Tesla",
//            text: "Рейтинг этого фильма больше чем 6?",
//            correctAnswer: false),
//        QuizQuestion(
//            image: "Vivarium",
//            text: "Рейтинг этого фильма больше чем 6?",
//            correctAnswer: false)
//    ]
    
    func requestNextQuestion() {
            //запускаем код в параллельном потоке
            DispatchQueue.global().async { [weak self] in
                guard let self else { return }
                
                let index = (0..<self.movies.count).randomElement() ?? 0    //выбираем произвольный элемент из массива
                self.requestNextQuestionByIndex(by: index)
            }
        }
        //метод получения вопроса по индексу
        func requestNextQuestionByIndex(by index: Int) {
            guard let movie = self.movies[safe: index] else { return}
            // обработка ошибки загрузки данных из URL
            var imageData = Data()
            
            do {
                imageData = try Data(contentsOf: movie.resizedImageURL)
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.delegate?.didFailedToUploadImage(for: index)     //ошибка загрузки изображения
                }
                return
            }
            // проверка на корректность ответа
            let rating = Float(movie.rating) ?? 0
            
            let text: String = "Рейтинг этого фильма больше, чем 9?"
            let correctAnswer = rating > 9
            
            //создание модели вопроса
            let question = QuizQuestion(image: imageData,
                                        text: text,
                                        correctAnswer: correctAnswer)
            //переход на следующий вопрос через делегат
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.delegate?.didReceiveNextQuestion(question: question)
            }
        }
    
}
