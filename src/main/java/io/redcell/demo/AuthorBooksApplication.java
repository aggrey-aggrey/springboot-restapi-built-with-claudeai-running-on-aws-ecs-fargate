package io.redcell.demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;

@SpringBootApplication
@EnableJpaAuditing
public class AuthorBooksApplication {

	public static void main(String[] args) {
		SpringApplication.run(AuthorBooksApplication.class, args);
	}

}
