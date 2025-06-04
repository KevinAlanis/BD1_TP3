package com.registro.usuarios.controlador;

import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class RegistroControlador {

	@GetMapping("/login")
	public String iniciarSesion() {
		return "login";
	}
	
	@GetMapping("/")
	public String defaultAfterLogin(Authentication authentication) {
		if (authentication.getAuthorities().stream()
			.anyMatch(r -> r.getAuthority().equals("ROLE_ADMIN"))) {
			return "redirect:/admin/dashboard";
		}
		return "redirect:/user/dashboard";
	}
}
