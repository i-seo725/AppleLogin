//
//  AuthenticationManager.swift
//  AppleLogin
//
//  Created by 이은서 on 12/29/23.
//

import Foundation
import LocalAuthentication //FaceID, TouchID

/*
 - 권한 요청: Info: Privacy - Face ID Usage Description 추가
 - FaceID가 없다면? 다른 인증 방법(비밀번호, 패턴 그리기 등) 권장하기, FaceID 등록 유도
 - FaceID 변경된 거 감지: domainStateData 데이터로 분기 처리 (안경, 마스크 쓰고 할 땐 변경 안됨)
 - 인증이 계속 실패할 때: FallBack에 대한 처리 필요, 비밀번호 등 다른 인증 방법으로 처리하게 해주기
 - FaceID 결과는 메인쓰레드를 보장하지 않음, DispatchQueue.main.async 구문 필요
 - 한 화면에서 FaceID 인증 성공 시 해당 화면에 대해서는 앱을 다시 켜지 않는 한 success 상태 유지(클래스의 인스턴스가 유지됨)
   -> SwiftUI에서는? state가 변경되면 body가 렌더링돼서 뷰가 다시 그려져 FaceID 및 다른 요소 모두 초기화 -> 재인증 필요
 
 - 실제 서비스 테스트 + LSLP 생체 인증 연동: 어느 시점, 어느 화면에 인증을 해서 언제까지 쓸 수 있게 할 지?
 */

final class AuthenticationManager {
    
    static let shared = AuthenticationManager()
    private init() { }
    
    var selectedPolicy: LAPolicy = .deviceOwnerAuthenticationWithBiometrics //생체 인증(FaceID+TouchID 따로 구현 안해도 됨)
    
    //인증 로직
    func auth() {
        let context = LAContext()
        context.localizedCancelTitle = "FaceID 인증 취소"
        context.localizedFallbackTitle = "비밀번호로 대신 인증하기"
        
        context.evaluatePolicy(selectedPolicy, localizedReason: "FaceID 인증이 필요합니다~~") { result, error in
            print(result) //Bool -> CompletionHandler로 보내서 다음 화면으로 넘기거나 처리
            
            if let error {
                let code = error._code
                let laError = LAError(LAError.Code(rawValue: code)!)
                print(laError)
            }
        }
    }
    
    //FaceID 사용 가능한 상태인지 확인
    func checkPolicy() -> Bool {
        let context = LAContext()
        let policy: LAPolicy = selectedPolicy
        
        return context.canEvaluatePolicy(policy, error: nil)
    }
    
    //변경 시
    func isFaceIDChanged() -> Bool {
        let context = LAContext()
        context.canEvaluatePolicy(selectedPolicy, error: nil)
        
        let state = context.evaluatedPolicyDomainState //생체 인증 정보
        
        //생체 인증 정보를 UD에 저장(자동 로그인, 새로운 인증 정보와 비교를 위해)
        //기존 저장된 DomainState와 새롭게 변경된 데이터를 비교
        
        print(state)
        return false //로직 추가
    }
    
}
