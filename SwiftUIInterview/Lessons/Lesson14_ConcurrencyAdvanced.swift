import SwiftUI

// MARK: - Lição 14 — Concurrency avançada
//
// Conceitos para entrevista sênior:
//  - async let          → paralelismo simples
//  - TaskGroup          → paralelismo dinâmico (n tasks)
//  - actor              → isolamento de estado mutável
//  - @MainActor         → garante execução na main thread (UI)
//  - AsyncStream        → ponte de callbacks → AsyncSequence
//  - Cancelamento       → Task.checkCancellation() / try Task.sleep cancela sozinho
//  - Sendable           → tipos seguros para cruzar isolamentos

// =====================================================================
// MARK: Actor — isolamento de estado
// =====================================================================
actor ImageCache {
    private var storage: [URL: Data] = [:]

    func get(_ url: URL) -> Data? { storage[url] }

    func set(_ data: Data, for url: URL) { storage[url] = data }

    func count() -> Int { storage.count }
}

// =====================================================================
// MARK: Repository com async let + TaskGroup
// =====================================================================
struct Repo: Decodable, Identifiable, Sendable {
    let id: Int
    let name: String
}

@MainActor
@Observable
final class ConcurrencyVM {
    var serial: [String] = []
    var parallel: [String] = []
    var streamTicks: [String] = []
    var cacheCount = 0
    var isRunning = false

    private let cache = ImageCache()
    private var streamTask: Task<Void, Never>?

    // 1) Sequencial vs paralelo via async let
    func runComparison() async {
        isRunning = true
        defer { isRunning = false }

        serial.removeAll()
        parallel.removeAll()

        // sequencial
        let s0 = Date()
        let a = await fakeFetch(label: "A", ms: 600)
        let b = await fakeFetch(label: "B", ms: 600)
        let c = await fakeFetch(label: "C", ms: 600)
        serial = [a, b, c, "⏱ \(Int(Date().timeIntervalSince(s0)*1000))ms"]

        // paralelo
        let p0 = Date()
        async let pa = fakeFetch(label: "A", ms: 600)
        async let pb = fakeFetch(label: "B", ms: 600)
        async let pc = fakeFetch(label: "C", ms: 600)
        let results = await [pa, pb, pc]
        parallel = results + ["⏱ \(Int(Date().timeIntervalSince(p0)*1000))ms"]
    }

    // 2) TaskGroup: nº dinâmico de tasks
    func runGroup(count: Int) async -> [String] {
        await withTaskGroup(of: String.self) { group in
            for i in 1...count {
                group.addTask { await Self.fakeFetchStatic(label: "T\(i)", ms: UInt64.random(in: 100...500)) }
            }
            var out: [String] = []
            for await result in group { out.append(result) }
            return out.sorted()
        }
    }

    // 3) AsyncStream: ponte timer → consumer
    func startStream() {
        streamTicks.removeAll()
        streamTask?.cancel()
        streamTask = Task { [weak self] in
            let stream = AsyncStream<Int> { continuation in
                Task {
                    while !Task.isCancelled {
                        try? await Task.sleep(for: .milliseconds(500))
                        continuation.yield(Int.random(in: 1...100))
                    }
                    continuation.finish()
                }
            }
            for await value in stream {
                guard !Task.isCancelled else { break }
                await MainActor.run { self?.streamTicks.append("\(value)") }
                if (self?.streamTicks.count ?? 0) >= 6 { break }
            }
        }
    }
    func stopStream() { streamTask?.cancel() }

    // 4) Actor — concorrência segura
    func hammerCache() async {
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<20 {
                group.addTask { [cache] in
                    let url = URL(string: "https://example.com/\(i % 5)")!
                    await cache.set(Data([UInt8(i)]), for: url)
                }
            }
        }
        cacheCount = await cache.count()
    }

    // helpers
    private func fakeFetch(label: String, ms: UInt64) async -> String {
        try? await Task.sleep(for: .milliseconds(ms))
        return label
    }
    private static func fakeFetchStatic(label: String, ms: UInt64) async -> String {
        try? await Task.sleep(for: .milliseconds(ms))
        return label
    }
}

struct Lesson14View: View {
    @State private var vm = ConcurrencyVM()
    @State private var groupOutput: [String] = []

    var body: some View {
        LessonScaffold(
            title: "14 — Concurrency avançada",
            goal: "async let, TaskGroup, actor, MainActor, AsyncStream, cancelamento.",
            exercise: """
            1. Adicione `Task.checkCancellation()` dentro do TaskGroup e teste cancelar mid-run.
            2. Converta `ImageCache` para usar `NSCache` por baixo (mantendo actor).
            3. Bônus: use `withThrowingTaskGroup` com fail-fast (cancela demais ao primeiro erro).
            """
        ) {
            GroupBox("async let — sequencial vs paralelo") {
                Button("Rodar comparação") { Task { await vm.runComparison() } }
                    .buttonStyle(.borderedProminent)
                    .disabled(vm.isRunning)
                if vm.isRunning { ProgressView() }
                Text("Sequencial: \(vm.serial.joined(separator: " · "))").font(.footnote)
                Text("Paralelo:   \(vm.parallel.joined(separator: " · "))").font(.footnote)
            }

            GroupBox("TaskGroup (dinâmico)") {
                Button("Disparar 8 tasks") {
                    Task { groupOutput = await vm.runGroup(count: 8) }
                }
                .buttonStyle(.bordered)
                Text(groupOutput.joined(separator: " · ")).font(.footnote)
            }

            GroupBox("AsyncStream") {
                HStack {
                    Button("Start") { vm.startStream() }
                    Button("Stop")  { vm.stopStream() }
                }.buttonStyle(.bordered)
                Text(vm.streamTicks.joined(separator: " · ")).font(.footnote.monospaced())
            }

            GroupBox("Actor (race-free)") {
                Button("20 writes concorrentes") { Task { await vm.hammerCache() } }
                    .buttonStyle(.bordered)
                Text("Itens no cache: \(vm.cacheCount)").font(.footnote)
            }
        }
    }
}

#Preview { NavigationStack { Lesson14View() } }
