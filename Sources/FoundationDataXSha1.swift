import Foundation

internal typealias XSha1State = (UInt32, UInt32, UInt32, UInt32, UInt32)

extension Foundation.Data {

    func xsha1() -> XSha1State {
        let seed: XSha1State = (0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476, 0xC3D2E1F0)

        // x86 ROL instruction emulation: ROL value, shift
        func ROL(value: UInt32, shift: UInt32) -> UInt32 {
            return shift == 0 ? value : value << shift | value >> (32 - shift)
        }

        typealias Sha1Operation = (UInt32, UInt32, UInt32) -> UInt32
        func work(state: inout XSha1State, magic: UInt32, data: UInt32, operation: Sha1Operation) {
            var tmp = state.4
            tmp = tmp &+ magic
            tmp = tmp &+ data
            tmp = tmp &+ ROL(value: state.0, shift: 5)
            tmp = tmp &+ operation(state.1, state.2, state.3)
            state = (tmp, state.0, ROL(value: state.1, shift: 30), state.2, state.3)
        }

        let input = arrayOfBytes()

        var data = [UInt32](repeating: 0, count: 80)

        for i in 0...(input.count / 4) {
            let offset = i * 4
            let byte1 = (offset + 0 < input.count) ? input[offset + 0] : 0
            let byte2 = (offset + 1 < input.count) ? input[offset + 1] : 0
            let byte3 = (offset + 2 < input.count) ? input[offset + 2] : 0
            let byte4 = (offset + 3 < input.count) ? input[offset + 3] : 0
            data[i] = UInt32(byte1) | UInt32(byte2) << 8 | UInt32(byte3) << 16 | UInt32(byte4) << 24
        }

        for i in 16..<80 {
            data[i] = ROL(value: 1, shift: (data[i - 16] ^ data[i - 8] ^ data[i - 14] ^ data[i - 3]) % 32)
        }

        var state = seed

        for i in  0..<20 {
            work(state: &state, magic: 0x5A827999, data: data[i]) { $2 ^ $0 & ($1 ^ $2) }
        }
        for i in 20..<40 {
            work(state: &state, magic: 0x6ED9EBA1, data: data[i]) { $0 ^ $1 ^ $2 }
        }
        for i in 40..<60 {
            work(state: &state, magic: 0x8F1BBCDC, data: data[i]) { $0 & $1 | $1 & $2 | $2 & $0 }
        }
        for i in 60..<80 {
            work(state: &state, magic: 0xCA62C1D6, data: data[i]) { $0 ^ $1 ^ $2 }
        }
        
        state.0 = state.0 &+ seed.0
        state.1 = state.1 &+ seed.1
        state.2 = state.2 &+ seed.2
        state.3 = state.3 &+ seed.3
        state.4 = state.4 &+ seed.4

        return state
    }

}
