r = results;
assert(~isempty(r));
r = r([r.C] == [r.mAcc_C]);

iS01 = [r.seed] == 1;

iN05 = [r.numTrain] == 5;
iN10 = [r.numTrain] == 10;
iN20 = [r.numTrain] == 20;
iN50 = [r.numTrain] == 50;

iEfv = strcmp({r.encoder}, 'fv');

iPca64  = [r.pcaDim] == 64;
iPca128 = [r.pcaDim] == 128;
iPcaBlk = [r.pcaBlockwise] == 1;

iSiftRoot = [r.dsiftRoot] == 1;
iLcs = [r.lcs] == 1;
iLcsRoot = [r.lcsRoot] == 1;
iLcsNrmC = [r.lcsNormComp] == 1;
iLcsNrmA = [r.lcsNormAll] == 1;
iPN = iLcsRoot;
iL2 = iLcsNrmC & iLcsNrmA;

iKlin = strcmp({r.kernel}, 'linear');
iKhel = strcmp({r.kernel}, 'hell');
iKchi = strcmp({r.kernel}, 'chi2');

iMtl = [r.mtl] == 1;
iStl = ~iMtl;

iMtlS = strcmp({r.mtl_ex}, 'S');
iMtlM = strcmp({r.mtl_ex}, 'M');

iSIFT = ~iLcs & iPca64;
iLCS = iLcs & iPca128 & ~iPN & ~iL2;
iLCSPN = iLcs & iPca128 & iPN & ~iL2;
iLCSL2 = iLcs & iPca128 & ~iPN & iL2;
iLCSPNL2 = iLcs & iPca128 & iPN & iL2;

iMtlSModel = [r.mtl_C1] == 1;

iMtlMModelN05 = ([r.mtl_C1] == 1e-2) & ([r.mtl_C2] == 1e+3);
iMtlMModelN10 = ([r.mtl_C1] == 1e-2) & ([r.mtl_C2] == 1e+3);
iMtlMModelN20 = ([r.mtl_C1] == 1e-3) & ([r.mtl_C2] == 1e+3);
iMtlMModelN50 = ([r.mtl_C1] == 1e-3) & ([r.mtl_C2] == 1e+5);
iMtlMModel = (iN05 & iMtlMModelN05) | (iN10 & iMtlMModelN10) | (iN20 & iMtlMModelN20) | (iN50 & iMtlMModelN50);