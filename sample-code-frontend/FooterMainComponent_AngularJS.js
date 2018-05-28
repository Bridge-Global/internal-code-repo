import { Component, OnInit } from '@angular/core';
import { LanguageViewModel } from '../viewmodel/language.viewmodel';
import { LanguageIntegration } from '../lookup';
import { MainService } from '../services/main.service';
import { UserViewModel } from '../viewmodel/user.viewmodel';

@Component({
  selector: 'app-footermain',
  templateUrl: './footermain.component.html',
  styleUrls: ['./footermain.component.scss'],
})
export class FootermainComponent implements OnInit {

  constructor(private mainService:MainService) { }

  ngOnInit() {
    this.getLanguageTexts();
  }
  user:UserViewModel=this.mainService.getCurrentUser();
  private _languageLookUp: LanguageIntegration = new LanguageIntegration();

  CopyRightsText="";
  language:LanguageViewModel[]= new Array(
    {key:this._languageLookUp.CopyRights,value:""},
  );
  getLanguageTexts(){
    this.mainService.GetLanguageTexts(this.language,this.user.languageCode,this.user.tenantId).subscribe(result =>{      
      this.language = result;
      this.CopyRightsText=this.language.find(i => i.key ===this._languageLookUp.CopyRights).value;
   });
  }

}