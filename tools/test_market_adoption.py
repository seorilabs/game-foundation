import copy
import datetime
import hashlib
import json
import subprocess
import tempfile
import unittest
from pathlib import Path
import validate_outgame as gate

ROOT=Path(__file__).resolve().parents[1]
class MarketAdoption(unittest.TestCase):
    def setUp(self):
        (ROOT/'build').mkdir(exist_ok=True)
        self.tmp=tempfile.TemporaryDirectory(dir=ROOT/'build');self.addCleanup(self.tmp.cleanup);self.folder=Path(self.tmp.name)
        self.profile=json.loads((ROOT/'godot/data/outgame/outgame-profile.json').read_text())
        self.target=None
        self.all_markets=False
        self.profile['adoptedMarkets']=['google_play','app_store']
        self.profile['services']['ads']['exposed']=True
        self.profile['services']['ads']['status']='wired'
        self.profile['marketServices']={'google_play':{'ads':True,'auth':False,'payments':False},'app_store':{'ads':False,'auth':False,'payments':False}}
    def errors(self):
        report={'kind':'market_sdk','passed':True,'recordedAt':datetime.datetime.now(datetime.timezone.utc).isoformat(),'sourceSha':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),'implementationFingerprint':gate.fingerprint(ROOT,self.profile),'checks':{'adopted_markets':True,'service_states':True},'markets':[],'artifacts':[]}
        artifact=self.folder/'raw.json';artifact.write_text('{}');report['artifacts']=[{'path':str(artifact.relative_to(ROOT)),'sha256':hashlib.sha256(artifact.read_bytes()).hexdigest(),'type':'report'}]
        for market in ([self.target] if self.target and not self.all_markets else self.profile['adoptedMarkets']):
            services={}
            for service in ['auth','payments','ads']:
                enabled=self.profile['marketServices'][market].get(service)
                services[service]={'status':'passed','checks':{'success':True,'cancelled':True,'failed':True}} if enabled else {'status':'not_adopted'}
            report['markets'].append({'market':market,'passed':True,'sdkVersion':'fixture-1','services':services})
        path=self.folder/'sdk.json';path.write_text(json.dumps(report));self.profile['evidence']['market_sdk']={'status':'passed','path':str(path.relative_to(ROOT)),'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'implementationFingerprint':report['implementationFingerprint']}
        return [e for e in gate.validate(ROOT,self.profile,stage='release',market=self.target) if e['detail'].startswith('market_sdk') or e['category']=='invalid_market_services']
    def test_android_ads_do_not_require_ios_ads(self): self.assertEqual([],self.errors())
    def test_one_market_lane_preserves_other_market_debt(self):
        self.target='google_play'
        self.assertEqual([],self.errors())
    def test_full_valid_report_can_be_used_for_one_lane(self):
        self.target='google_play';self.all_markets=True
        self.assertEqual([],self.errors())
    def test_incomplete_market_map_rejected(self):
        del self.profile['marketServices']['app_store']['ads']
        self.assertTrue(self.errors())
    def test_non_boolean_not_a_waiver(self):
        self.profile['marketServices']['app_store']['ads']='false'
        self.assertTrue(self.errors())
    def test_global_exposure_without_any_market_adoption_rejected(self):
        self.profile['marketServices']['google_play']['ads']=False
        self.assertTrue(self.errors())

if __name__=='__main__':unittest.main()
