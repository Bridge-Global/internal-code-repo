import React,{PropTypes} from "react";

import FlowLayout from "../FlowLayout";
import ChangeColor from "../ChangeColor";

import FaFacebook from "react-icons/lib/fa/facebook-official";
import FaGoogle from "react-icons/lib/fa/google-plus-square";
import FaLinkedIn from "react-icons/lib/fa/linkedin-square";
import axios from "axios";
import { Link } from "react-router";
import { browserHistory } from 'react-router';// In react-router v3 only


require("../styles/LoginStyle.scss");

const iconStyle = {
	fontSize: "54px",
};

export default class Login extends React.Component {
	// TODO: Get actual amount of flows/systems

	constructor (props)
	{
		super(props);
		this.state = {
			email : '',
			password : '',
			message : '',
			formErrors : {email : '', password : ''},
			emailValid : false,
			passwordValid : false,
			formValid: false
		}
		

	}

	handleUserInput = (e) => {
		const name = e.target.name;
		const value = e.target.value;
		this.setState({[name] : value },
						() => { this.validateField(name , value) });
	}

	validateField(fieldName, value) {
		let fieldValidationErrors = this.state.formErrors;
		let emailValid = this.state.emailValid;
		let passwordValid = this.state.passwordValid;

		switch(fieldName) {
			case 'email':
				emailValid = value.match(/^([\w.%+-]+)@([\w-]+\.)+([\w]{2,})$/i);
				fieldValidationErrors.email = emailValid ? '' : ' is invalid';
				break;

		  	case 'password':
				passwordValid = value.length >= 6;
				fieldValidationErrors.password = passwordValid ? '': ' is too short';
				break;
		  	default:
				break;
		}

		this.setState({formErrors: fieldValidationErrors,
			emailValid: emailValid,
			passwordValid: emailValid
			}, this.validateForm);
	}
	validateForm() {
		this.setState({formValid: this.state.emailValid && this.state.emailValid});
	}
	
	errorClass(error) {
		return(error.length === 0 ? '' : 'has-error');
	}

	handleSubmit = (e) =>  {
		e.preventDefault();

		var self = this;
		axios.post(this.props.action,{'email':this.state.email,'password':this.state.password}).then(function(response){
			if(response.data.length > 0){

			  	self.setState({
					message: 'You have logged in successfully'
				});
				
				browserHistory.push('/dashboard'); // In react-router v3 only
			}else{

				console.log("failure");
				self.setState({
					message: 'Incorrect username or password'
				});
			   
			}
			
		}).catch(function(error){
			//Some error occurred
		});
		
	  }
					

	

	render() {
		return (
    		<FlowLayout>
  				<h2> SIGN IN </h2>
				  <h3 className="faded"> 6 imponerande flöden utifrån 9 system. Låt oss spara dem åt dig </h3><br/>
				<ChangeColor/>
				<div class="login_box">
					<button className="btn btn-register-in facebook-radius" onClick={this.fbLogin}>
						<FaFacebook style={iconStyle}/>
					</button>
					<button className="btn btn-register-in" onClick={this.goLogin}>
						<FaGoogle style={iconStyle}/>
					</button>
					<button className="btn btn-register-in last-btn-register" onClick={this.liLogin}>
						<FaLinkedIn style={iconStyle}/>
					</button><br/><br/>
					
						<span className="errorClass">{this.state.message}</span>
						<form name="login-form" id="login-form" onSubmit={this.handleSubmit} action={this.props.action} method={this.props.method}>
							<div className="form-group">
								<input name="email" id="email" required className="form-control" value={this.state.email}
							placeholder="Email"
							onChange={this.handleUserInput} />
							<span className="errorClass">{this.state.formErrors.email}</span>
							</div>
							<div className="form-group">
								<input type="password" name="password" id="password" required className="form-control" value={this.state.password}
							placeholder="Password"
							onChange={this.handleUserInput} />
							<span className="errorClass">{this.state.formErrors.password}</span>
							</div>

							<button type="submit" className="btn btn-login-btn"  disabled={!this.state.formValid}>
								Login <span>→</span>
							</button><br/><br/>
						</form>					
					
				
				<Link to="/register"  className="link link-header no-border"> <span>REGISTRATION</span> </Link>
				</div>
  			</FlowLayout>
    	);
	}

	fbLogin() {
    	window.location = "/auth/facebook";
	}
	goLogin() {
    	window.location = "/auth/google";
	}
	liLogin() {
		window.location = "/auth/linkedin";
	}
}

Login.defaultProps = {
	action : "/api/post/login",
	method : "POST"
}
