package ohos_app_cangjie_eudi_cjetsi_1196x2.lote_consultation

import std.collection.*
import ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_core.*
import ohos_app_cangjie_eudi_cjetsi_1196x2.lote_data_model.*

public enum LoTELoadConstraints {
    | DoNotLoadOtherPointers
    | LoadOtherPointers(Int64, Int64, Int64)
}

public enum LoadLoTEEvent {
    | LoTELoaded(ListOfTrustedEntities, Uri, Int64)
    | ResourceNotFound(Uri, Option<Exception>)
    | InvalidJWTSignature(Uri, Option<Exception>)
    | FailedToParseJwt(Uri, Option<Exception>)
    | MaxDepthReached(Uri, Int64)
    | MaxListsReached(Uri, Int64)
    | CircularReferenceDetected(Uri)
    | Error(Uri, Exception)
}

public class ContinueOnProblem {
    private let fn: (Bool, ArrayList<LoadLoTEEvent>) -> Bool

    public init(fn: (Bool, ArrayList<LoadLoTEEvent>) -> Bool) {
        this.fn = fn
    }

    public func invoke(lotePresent: Bool, problems: ArrayList<LoadLoTEEvent>): Bool {
        this.fn(lotePresent, problems)
    }

    public static func always(): ContinueOnProblem {
        ContinueOnProblem({ _: Bool, _: ArrayList<LoadLoTEEvent> => true })
    }

    public static func never(): ContinueOnProblem {
        ContinueOnProblem({ _: Bool, _: ArrayList<LoadLoTEEvent> => false })
    }

    public static func alwaysIfDownloaded(): ContinueOnProblem {
        ContinueOnProblem({ downloaded: Bool, _: ArrayList<LoadLoTEEvent> => downloaded })
    }
}

class LoTELoadState {
    public let visitedUris = ArrayList<String>()
    public var downloadsCounter: Int64 = 0
}

/// Recursively loads a LoTE and the lists it points to.
public class LoadLoTEAndPointers {
    private let constraints: LoTELoadConstraints
    private let verifyJwtSignature: VerifyJwtSignature
    private let loadLoTE: LoadLoTE
    private let parseJwt: ParseJwt

    public init(
        constraints: LoTELoadConstraints,
        verifyJwtSignature: VerifyJwtSignature,
        loadLoTE: LoadLoTE,
        parseJwt!: ParseJwt = ParseJwt()
    ) {
        match (constraints) {
            case LoTELoadConstraints.LoadOtherPointers(parallelism, maxDepth, maxLists) =>
                if (parallelism <= 0) {
                    throw IllegalArgumentException("Parallelism must be greater than 0")
                }
                if (maxDepth <= 0) {
                    throw IllegalArgumentException("Max depth must be greater than 0")
                }
                if (maxLists <= 0) {
                    throw IllegalArgumentException("Max downloads must be greater than 0")
                }
            case LoTELoadConstraints.DoNotLoadOtherPointers => ()
        }
        this.constraints = constraints
        this.verifyJwtSignature = verifyJwtSignature
        this.loadLoTE = loadLoTE
        this.parseJwt = parseJwt
    }

    public func invoke(uri: Uri): ArrayList<LoadLoTEEvent> {
        let events = ArrayList<LoadLoTEEvent>()
        let state = LoTELoadState()
        this.processLoTE(events, state, uri, 0)
        events
    }

    private func processLoTE(
        events: ArrayList<LoadLoTEEvent>,
        state: LoTELoadState,
        uri: Uri,
        depth: Int64
    ): Unit {
        consultationPlatform().runIo({ =>
            match (this.constraints) {
                case LoTELoadConstraints.LoadOtherPointers(_, maxDepth, maxLists) =>
                    match (this.constraintViolation(state, uri, depth, maxDepth, maxLists)) {
                        case Some(problem) =>
                            events.add(problem)
                            return
                        case None => ()
                    }
                case LoTELoadConstraints.DoNotLoadOtherPointers => ()
            }
            state.visitedUris.add(uri.value)
            try {
                match (this.loadLoTE.invoke(uri)) {
                    case LoadLoTEOutcome.Loaded(content) =>
                        state.downloadsCounter = state.downloadsCounter + 1
                        let event = this.verifySignatureAndParseJwt(uri, depth, content)
                        events.add(event)
                        match (event) {
                            case LoadLoTEEvent.LoTELoaded(lote, _, _) =>
                                this.handleOtherPointers(events, state, depth, lote)
                            case _ => ()
                        }
                    case LoadLoTEOutcome.NotFound(cause) =>
                        events.add(LoadLoTEEvent.ResourceNotFound(uri, cause))
                }
            } catch (e: Exception) {
                events.add(LoadLoTEEvent.Error(uri, e))
            } finally {
                removeVisited(state.visitedUris, uri.value)
            }
        })
    }

    private func handleOtherPointers(
        events: ArrayList<LoadLoTEEvent>,
        state: LoTELoadState,
        parentDepth: Int64,
        lote: ListOfTrustedEntities
    ): Unit {
        match (this.constraints) {
            case LoTELoadConstraints.DoNotLoadOtherPointers => return
            case LoTELoadConstraints.LoadOtherPointers(_, _, _) => ()
        }
        match (lote.schemeInformation.pointersToOtherLists) {
            case None => return
            case Some(pointers) =>
                if (pointers.size == 0) {
                    return
                }
                for (pointer in pointers) {
                    this.processLoTE(events, state, pointer.location, parentDepth + 1)
                }
        }
    }

    private func verifySignatureAndParseJwt(uri: Uri, depth: Int64, jwt: String): LoadLoTEEvent {
        match (this.verifyJwtSignature.invoke(jwt)) {
            case VerifyJwtSignatureOutcome.Verified(verified) =>
                match (this.parseJwt.invoke(verified)) {
                    case ParseJwtOutcome.Parsed(_, claims) =>
                        LoadLoTEEvent.LoTELoaded(claims.listOfTrustedEntities, uri, depth)
                    case ParseJwtOutcome.ParseFailed(cause) =>
                        LoadLoTEEvent.FailedToParseJwt(uri, cause)
                }
            case VerifyJwtSignatureOutcome.NotVerified(cause) =>
                LoadLoTEEvent.InvalidJWTSignature(uri, cause)
        }
    }

    private func constraintViolation(
        state: LoTELoadState,
        uri: Uri,
        depth: Int64,
        maxDepth: Int64,
        maxLists: Int64
    ): ?LoadLoTEEvent {
        if (depth > maxDepth) {
            return Some(LoadLoTEEvent.MaxDepthReached(uri, maxDepth))
        }
        if (state.downloadsCounter >= maxLists) {
            return Some(LoadLoTEEvent.MaxListsReached(uri, maxLists))
        }
        if (visitedContains(state.visitedUris, uri.value)) {
            return Some(LoadLoTEEvent.CircularReferenceDetected(uri))
        }
        None
    }
}

public class LoTELoadResult {
    public let list: Option<LoadLoTEEvent>
    public let otherLists: ArrayList<LoadLoTEEvent>
    public let problems: ArrayList<LoadLoTEEvent>

    public init(
        list: Option<LoadLoTEEvent>,
        otherLists: ArrayList<LoadLoTEEvent>,
        problems: ArrayList<LoadLoTEEvent>
    ) {
        this.list = list
        this.otherLists = otherLists
        this.problems = problems
    }

    public static func collect(
        events: ArrayList<LoadLoTEEvent>,
        continueOnProblem!: ContinueOnProblem = ContinueOnProblem.never()
    ): LoTELoadResult {
        var mainList: Option<LoadLoTEEvent> = None
        let otherLists = ArrayList<LoadLoTEEvent>()
        let problems = ArrayList<LoadLoTEEvent>()
        for (event in events) {
            match (event) {
                case LoadLoTEEvent.LoTELoaded(_, _, depth) =>
                    if (depth == 0) {
                        match (mainList) {
                            case Some(_) => throw IllegalStateException("Multiple LoTEs downloaded with depth 0")
                            case None => mainList = Some(event)
                        }
                    } else {
                        otherLists.add(event)
                    }
                case _ =>
                    problems.add(event)
                    let present: Bool = match (mainList) {
                        case Some(_) => true
                        case None => false
                    }
                    if (!continueOnProblem.invoke(present, problems)) {
                        break
                    }
            }
        }
        if (otherLists.size > 0) {
            match (mainList) {
                case None => throw IllegalStateException("Other LoTEs downloaded before main LoTE")
                case Some(_) => ()
            }
        }
        LoTELoadResult(mainList, otherLists, problems)
    }

    public func loadedMain(): Option<ListOfTrustedEntities> {
        match (this.list) {
            case Some(LoadLoTEEvent.LoTELoaded(lote, _, _)) => Some(lote)
            case _ => None
        }
    }

    public func loadedOthers(): ArrayList<ListOfTrustedEntities> {
        let out = ArrayList<ListOfTrustedEntities>()
        for (event in this.otherLists) {
            match (event) {
                case LoadLoTEEvent.LoTELoaded(lote, _, _) => out.add(lote)
                case _ => ()
            }
        }
        out
    }
}

func visitedContains(uris: ArrayList<String>, value: String): Bool {
    for (item in uris) {
        if (item == value) {
            return true
        }
    }
    false
}

func removeVisited(uris: ArrayList<String>, value: String): Unit {
    let kept = ArrayList<String>()
    var skipped = false
    for (item in uris) {
        if (!skipped && item == value) {
            skipped = true
        } else {
            kept.add(item)
        }
    }
    uris.clear()
    for (item in kept) {
        uris.add(item)
    }
}

public func eventIsProblem(event: LoadLoTEEvent): Bool {
    match (event) {
        case LoadLoTEEvent.LoTELoaded(_, _, _) => false
        case _ => true
    }
}

public func eventCause(event: LoadLoTEEvent): Option<Exception> {
    match (event) {
        case LoadLoTEEvent.Error(_, cause) => Some(cause)
        case LoadLoTEEvent.ResourceNotFound(_, cause) => cause
        case LoadLoTEEvent.InvalidJWTSignature(_, cause) => cause
        case LoadLoTEEvent.FailedToParseJwt(_, cause) => cause
        case _ => None
    }
}

public func eventToString(event: LoadLoTEEvent): String {
    match (event) {
        case LoadLoTEEvent.LoTELoaded(_, uri, depth) => "LoTELoaded(${uri.value}, depth=${depth})"
        case LoadLoTEEvent.ResourceNotFound(uri, _) => "ResourceNotFound(${uri.value})"
        case LoadLoTEEvent.InvalidJWTSignature(uri, _) => "InvalidJWTSignature(${uri.value})"
        case LoadLoTEEvent.FailedToParseJwt(uri, _) => "FailedToParseJwt(${uri.value})"
        case LoadLoTEEvent.MaxDepthReached(uri, maxDepth) => "MaxDepthReached(${uri.value}, max=${maxDepth})"
        case LoadLoTEEvent.MaxListsReached(uri, maxLists) => "MaxListsReached(${uri.value}, max=${maxLists})"
        case LoadLoTEEvent.CircularReferenceDetected(uri) => "CircularReferenceDetected(${uri.value})"
        case LoadLoTEEvent.Error(uri, cause) => "Error(${uri.value}: ${cause})"
    }
}
