package ohos_app_cangjie_eudi_cjetsi_1196x2.lote_consultation

import std.collection.*
import std.sync.*
import ohos_app_cangjie_eudi_cjetsi_1196x2.consultation_core.*
import ohos_app_cangjie_eudi_cjetsi_1196x2.lote_data_model.*

/// A loaded LoTE together with pointer lists fetched from it.
public class LoadedLoTE {
    public let list: ListOfTrustedEntities
    public let otherLists: ArrayList<ListOfTrustedEntities>

    public init(list: ListOfTrustedEntities, otherLists: ArrayList<ListOfTrustedEntities>) {
        this.list = list
        this.otherLists = otherLists
    }

    public func servicesOfType(svcType: Uri): ArrayList<TrustedEntityService> {
        let out = ArrayList<TrustedEntityService>()
        collectServicesOfType(this.list, svcType, out)
        for (other in this.otherLists) {
            collectServicesOfType(other, svcType, out)
        }
        out
    }

    public func trustAnchorsFor<TRUST_ANCHOR>(
        svcType: Uri,
        createTrustAnchors: (ServiceDigitalIdentity) -> ArrayList<TRUST_ANCHOR>
    ): ArrayList<TRUST_ANCHOR> {
        let out = ArrayList<TRUST_ANCHOR>()
        for (service in this.servicesOfType(svcType)) {
            let anchors = createTrustAnchors(service.information.digitalIdentity)
            for (anchor in anchors) {
                out.add(anchor)
            }
        }
        out
    }
}

/// GetTrustAnchors backed by a LoTE location: load/verify the document, then
/// return anchors for the queried service-type URI.
public class GetTrustAnchorsFromLoTE<TRUST_ANCHOR> <: GetTrustAnchors<Uri, TRUST_ANCHOR> {
    private let loTEDownloadUrl: Uri
    private let loadLoTEAndPointers: LoadLoTEAndPointers
    private let continueOnProblem: ContinueOnProblem
    private let createTrustAnchors: (ServiceDigitalIdentity) -> ArrayList<TRUST_ANCHOR>
    private let mutex = Mutex()

    public init(
        loTEDownloadUrl: Uri,
        loadLoTEAndPointers: LoadLoTEAndPointers,
        createTrustAnchors: (ServiceDigitalIdentity) -> ArrayList<TRUST_ANCHOR>,
        continueOnProblem!: ContinueOnProblem = ContinueOnProblem.never()
    ) {
        this.loTEDownloadUrl = loTEDownloadUrl
        this.loadLoTEAndPointers = loadLoTEAndPointers
        this.createTrustAnchors = createTrustAnchors
        this.continueOnProblem = continueOnProblem
    }

    public func invoke(query: Uri): ?NonEmptyList<TRUST_ANCHOR> {
        var result: ?NonEmptyList<TRUST_ANCHOR> = None
        synchronized(this.mutex) {
            let loaded = this.loadLoTe()
            result = NonEmptyList<TRUST_ANCHOR>.nelOrNull(loaded.trustAnchorsFor(query, this.createTrustAnchors))
        }
        result
    }

    private func loadLoTe(): LoadedLoTE {
        let events = this.loadLoTEAndPointers.invoke(this.loTEDownloadUrl)
        let result = LoTELoadResult.collect(events, continueOnProblem: this.continueOnProblem)
        match (result.loadedMain()) {
            case Some(mainList) => LoadedLoTE(mainList, result.loadedOthers())
            case None => this.raiseLoadingProblems(result)
        }
    }

    private func raiseLoadingProblems(result: LoTELoadResult): LoadedLoTE {
        var msg = "Failed to load LoTE from ${this.loTEDownloadUrl.value}\nProblems encountered during loading:\n"
        var index: Int64 = 1
        for (problem in result.problems) {
            msg = msg + "${index}. ${eventToString(problem)}\n"
            match (eventCause(problem)) {
                case Some(cause) => msg = msg + "    cause: ${cause}\n"
                case None => ()
            }
            index = index + 1
        }
        throw IllegalStateException(msg)
    }
}

func collectServicesOfType(
    lote: ListOfTrustedEntities,
    svcType: Uri,
    out: ArrayList<TrustedEntityService>
): Unit {
    match (lote.entities) {
        case None => ()
        case Some(entities) =>
            for (entity in entities) {
                for (svc in entity.services) {
                    match (svc.information.typeIdentifier) {
                        case Some(tid) =>
                            if (tid.value == svcType.value) {
                                out.add(svc)
                            }
                        case None => ()
                    }
                }
            }
    }
}
