import Combine
import Foundation

protocol TC_Feature {
    associatedtype State
    associatedtype Action
    static func reduce(state: inout State, action: Action) -> TC_Effect<Action>
}

struct TC_Effect<Action> {
    let perform: (@escaping (Action) -> Void) -> Void

    static var none: TC_Effect<Action> {
        TC_Effect { _ in }
    }

    static func fire(_ work: @escaping (@escaping (Action) -> Void) -> Void) -> TC_Effect<Action> {
        TC_Effect(perform: work)
    }

    static func send(_ action: Action) -> TC_Effect<Action> {
        TC_Effect { dispatch in dispatch(action) }
    }

    static func merge(_ effects: [TC_Effect<Action>]) -> TC_Effect<Action> {
        TC_Effect { dispatch in
            for effect in effects { effect.perform(dispatch) }
        }
    }

    static func delayed(_ action: Action, by seconds: TimeInterval) -> TC_Effect<Action> {
        TC_Effect { dispatch in
            let timer = Timer(timeInterval: seconds, repeats: false) { _ in
                dispatch(action)
            }
            RunLoop.main.add(timer, forMode: .common)
        }
    }
}

final class TC_Store<F: TC_Feature> {
    let state: CurrentValueSubject<F.State, Never>
    let events: PassthroughSubject<F.Action, Never>

    init(initial: F.State) {
        self.state = CurrentValueSubject(initial)
        self.events = PassthroughSubject()
    }

    func dispatch(_ action: F.Action) {
        var working = state.value
        let effect = F.reduce(state: &working, action: action)
        state.send(working)
        events.send(action)
        effect.perform { [weak self] follow in
            self?.dispatch(follow)
        }
    }
}
