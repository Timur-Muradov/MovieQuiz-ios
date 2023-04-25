import UIKit

final class MovieQuizViewController: UIViewController, QuestionFactoryDelegate {
    
    
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.layer.cornerRadius = 20
        imageView.layer.borderWidth = 0
        
        questionFactory = QuestionFactory(moviesLoader: MoviesLoader(), delegate: self)
        statisticService = StaticServiceImpl()
        
        showLoadingIndicator()
        questionFactory?.loadData()
        alertPresenter = AlertPresenterImpl(viewController: self)
        
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return.lightContent
    }
    
    // MARK: - QuestionFactoryDelegate
    
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question = question else {
            return
        }
        
        currentQuestion = question
        let viewModel = convert(model: question)
        DispatchQueue.main.async { [weak self] in
            self?.show(quiz: viewModel)
        }
    }
    
    private let questionsCount: Int = 10
    private var questionFactory: QuestionFactoryProtocol?
    private var currentQuestion: QuizQuestion?
    private var alertPresenter: AlertPresenter?
    private var statisticService: StatisticService?
    
    
    private func showAnswerResult(isCorrect: Bool) {
        
        if isCorrect {
            correctAnswers += 1
        }
        yesButtonClicked.isEnabled = false
        noButtonClicked.isEnabled = false
        
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = isCorrect ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            self.showNextQuestionOrResults()
            
        }
        
    }
    
    @IBOutlet private var yesButtonClicked: UIButton!
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        
        guard let currentQuestion = currentQuestion else {
            return
        }
        
        let givenAnswer = true
        showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
        
    }
    @IBOutlet private var noButtonClicked: UIButton!
    @IBAction private func noButtonClicked(_ sender: UIButton) {
        
        guard let currentQuestion = currentQuestion else {
            return
        }
        
        let givenAnswer = false
        showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
    }
    
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var textLabel: UILabel!
    @IBOutlet private var counterLabel: UILabel!
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!
    
    private func show(quiz step: QuizStepViewModel) {
        
        imageView.image = step.image
        textLabel.text = step.question
        counterLabel.text = step.questionNumber
        
        view.alpha = 1
        
    }
    
    func showLoadingIndicator() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }
    
    func hideLoadingIndicator() {
        activityIndicator.isHidden = true
    }
    
    private func showNetworkError(message: String) {
        
        hideLoadingIndicator()
        
        let model = AlertModel(title: "Ошибка",
                               message: message,
                               buttonText: "Попробовать еще раз") { [weak self] in
            guard let self = self else { return }
            
            self.currentQuestionIndex = 0
            self.correctAnswers = 0
            
            self.questionFactory?.loadData()
        }
        alertPresenter?.show(alertModel: model)
    }
    
    func didLoadDataFromServer() {
        activityIndicator.isHidden = true
        questionFactory?.requestNextQuestion()
    }
    
    func didFailToLoadData(with error: Error) {
        showNetworkError(message: error.localizedDescription)
    }
    
    private func showFinalResults() {
        
        statisticService?.store(correct: correctAnswers, total: questionsCount)
        
        let alertModel = AlertModel(
            title: "Игра окончена!",
            message: makeResultMessage(),
            buttonText: "Попробовать еще раз") { [weak self] in
                self?.currentQuestionIndex = 0
                self?.correctAnswers = 0
                self?.questionFactory?.requestNextQuestion()
            }
        alertPresenter?.show(alertModel: alertModel)
        
    }
    
    private func makeResultMessage() -> String {
        
        guard let statisticService = statisticService, let bestGame = statisticService.bestGame else {
            assertionFailure("error")
            return ""
        }
        let accuracy = String(format: "%.2f", statisticService.totalAccuracy)
        let totalPlaysCountLine = "Количество сыгранных квизов: \(statisticService.gamesCount)"
        let currentGameResultLine = "Ваш результат:\(correctAnswers)\\\(questionsCount)"
        let bestGameInfoLine = "Рекорд:\(bestGame.correct)\\\(bestGame.total)" + " (\(bestGame.date.dateTimeString))"
        let averageAccuracyLine = "Средняя точность: \(accuracy)%"
        
        let resultMessage = [
            currentGameResultLine, totalPlaysCountLine, bestGameInfoLine, averageAccuracyLine
        ].joined(separator: "\n")
        return resultMessage
    }
    
    private var currentQuestionIndex: Int = 0
    
    private func convert(model: QuizQuestion) -> QuizStepViewModel {
        return QuizStepViewModel(
            image: UIImage(data: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsCount)")
        
    }
    private var correctAnswers: Int = 0
    
    private func showNextQuestionOrResults() {
        
        imageView.layer.borderWidth = 0
        
        if currentQuestionIndex == questionsCount - 1 {
            showFinalResults()
        } else {
            currentQuestionIndex += 1
            self.questionFactory?.requestNextQuestion()
            
        }
        yesButtonClicked.isEnabled = true
        noButtonClicked.isEnabled = true
    }
    
    func didfailedToUploadImage(for quizQuestionIndex: Int) {
        let alert = AlertModel(title: "Ошибка",
                               message: "Не удалось загрузить изображение",
                               buttonText: "Попробовать еще раз") { [weak self] in
            guard let self else { return }
            self.imageView.layer.borderWidth = 0
            self.questionFactory?.requestNextQuestionByIndex(by: quizQuestionIndex)
        }
        view.alpha = 0.6
        alertPresenter?.show(alertModel: alert)
    }
    
}
