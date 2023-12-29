//
//  ViewController.swift
//  AppleLogin
//
//  Created by 이은서 on 12/28/23.
//

import UIKit
import AuthenticationServices

/*
 소셜 로그인(페북/구글/카카오/네이버 등) 구현할 때 애플 로그인 구현 필수
 자기 회사 거면 애플 로그인 안 붙여도 됨, 카카오에서 카카오, 인스타에서 페북
 자체 로그인만 구성될 경우 애플 로그인 필수 아님
 */

class MainViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGray
    }
}


class ViewController: UIViewController {

    @IBOutlet weak var appleLoginButton: ASAuthorizationAppleIDButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        appleLoginButton.addTarget(self, action: #selector(appleLoginButtonClicked), for: .touchUpInside)
        
    }
    
    @IBAction func faceIDButtonClicked(_ sender: UIButton) {
        AuthenticationManager.shared.auth()
    }
    
    
    @objc func appleLoginButtonClicked() {
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.email, .fullName]
        
        //아래에서 위로 뜨는 로그인 화면
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self //로직
        controller.presentationContextProvider = self //presentation
        controller.performRequests() //신호 보내기
    }
}


extension ViewController: ASAuthorizationControllerPresentationContextProviding {
    
    //로그인 화면 띄우는 메서드
    //첫시도 : 계속, email, fullname 정보 제공
    //두번째 시도 : 로그인 하시겠습니까? email, fullname nil값으로 옴
    //사용자 정보를 계속 제공하지 않음 최초에만 제공 -> 토큰을 해제해서 얻어야 함
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window! //윈도우에 꽉 차게 띄워라
    }
}

extension ViewController: ASAuthorizationControllerDelegate {
    
    //성공했을 때: 루트뷰 바꾸기, 메인 페이지로 이동
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        
        switch authorization.credential {
        case let appleIDCredential as ASAuthorizationAppleIDCredential: //애플 아이디 인증
            
            print(appleIDCredential)
            
            let userIdentifier = appleIDCredential.user
            let fullName = appleIDCredential.fullName
            let email = appleIDCredential.email
            guard let token = appleIDCredential.identityToken, let tokenToString = String(data: token, encoding: .utf8) else {
                print("Token Error")
                return
            }
            
            //UserDefault에 내용 저장 필요
            //API로 서버에 POST 필요
            //서버에 Request 후 Response를 받게 되면 성공 시 화면 전환
            print(userIdentifier)
            print(fullName ?? "noname")
            print(email ?? "no email")
            print(tokenToString)
            
            if email?.isEmpty ?? true {
                let result = decode(jwtToken: tokenToString)["email"] as? String ?? ""
                print(result)
            }
            
            UserDefaults.standard.setValue(userIdentifier, forKey: "User")
            
            DispatchQueue.main.async {
                self.present(MainViewController(), animated: true)
            }
            
            
        case let passwordCredential as ASPasswordCredential: //키체인 연동
            
            print(passwordCredential)
            
            let username = passwordCredential.user
            let password = passwordCredential.password
            
            print(username)
            print(password)
            
        default: break
        }
        
    }
    
    //실패했을 때
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Login Failed ", error.localizedDescription)
    }
    
}

private func decode(jwtToken jwt: String) -> [String: Any] {
    
    func base64UrlDecode(_ value: String) -> Data? {
        var base64 = value
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        let length = Double(base64.lengthOfBytes(using: String.Encoding.utf8))
        let requiredLength = 4 * ceil(length / 4.0)
        let paddingLength = requiredLength - length
        if paddingLength > 0 {
            let padding = "".padding(toLength: Int(paddingLength), withPad: "=", startingAt: 0)
            base64 = base64 + padding
        }
        return Data(base64Encoded: base64, options: .ignoreUnknownCharacters)
    }
    func decodeJWTPart(_ value: String) -> [String: Any]? {
        guard let bodyData = base64UrlDecode(value),
              let json = try? JSONSerialization.jsonObject(with: bodyData, options: []), let payload = json as? [String: Any] else {
            return nil
        }
        
        return payload
    }
    
    let segments = jwt.components(separatedBy: ".")
    return decodeJWTPart(segments[1]) ?? [:]
}
